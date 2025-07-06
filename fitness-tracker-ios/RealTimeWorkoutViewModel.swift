import SwiftUI
import HealthKit
import Combine

// MARK: - Exercise Types
enum ExerciseType: CaseIterable {
    case dumbbellPress
    case abs
    case shoulderPress
    
    var displayName: String {
        switch self {
        case .dumbbellPress:
            return "ダンベルプレス"
        case .abs:
            return "腹筋"
        case .shoulderPress:
            return "ショルダープレス"
        }
    }
    
    var icon: String {
        switch self {
        case .dumbbellPress:
            return "dumbbell.fill"
        case .abs:
            return "figure.core.training"
        case .shoulderPress:
            return "figure.strengthtraining.traditional"
        }
    }
}

// MARK: - Output
struct RealTimeWorkoutOutput {
    var selectedWorkoutType: HKWorkoutActivityType = .traditionalStrengthTraining
    var isWorkoutActive: Bool = false
    var isPaused: Bool = false
    var workoutStartTime: Date?
    var heartRate: Double = 0
    var caloriesBurned: Double = 0
    var workoutDuration: TimeInterval = 0
    var currentSet: Int = 1
    var totalSets: Int = 5
    var restTimeRemaining: Int = 0
    var averageWeight: Double = 0
    var totalWeight: Double = 0
    var recentWorkouts: [HKWorkout] = []
    var isAuthorized: Bool = false
    var isLoading: Bool = false
    
    // 音声ガイド関連
    var isVoiceGuided: Bool = false
    var currentExercise: ExerciseType = .dumbbellPress
    var currentReps: Int = 10
    var currentWeight: Double = 20.0
    
    // 計算プロパティ
    var formattedTime: String {
        let minutes = Int(workoutDuration) / 60
        let seconds = Int(workoutDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var progress: Double {
        guard totalSets > 0 else { return 0 }
        return Double(currentSet - 1) / Double(totalSets)
    }
}

// MARK: - ViewModel
@MainActor
class RealTimeWorkoutViewModel: ObservableObject {
    @Published var output = RealTimeWorkoutOutput()
    
    private let healthKitManager: HealthKitManager
    private let voiceManager = VoiceGuideManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    // TimerはView側でonReceiveを使用するため、ここでは不要
    
    // 利用可能なワークアウトタイプ（筋トレ専用）
    static let availableWorkoutTypes: [HKWorkoutActivityType] = [
        .traditionalStrengthTraining
    ]
    
    init(healthKitManager: HealthKitManager) {
        self.healthKitManager = healthKitManager
        setupBindings()
        setupTimer()
        fetchRecentWorkouts()
    }
    
    private func setupBindings() {
        // HealthKitManagerのデータ変更を監視
        healthKitManager.$isWorkoutActive
            .assign(to: \.output.isWorkoutActive, on: self)
            .store(in: &cancellables)
        
        healthKitManager.$heartRate
            .assign(to: \.output.heartRate, on: self)
            .store(in: &cancellables)
        
        healthKitManager.$activeEnergy
            .assign(to: \.output.caloriesBurned, on: self)
            .store(in: &cancellables)
        
        healthKitManager.$isAuthorized
            .assign(to: \.output.isAuthorized, on: self)
            .store(in: &cancellables)
    }
    
    private func setupTimer() {
        // TimerはView側でonReceiveを使用するため、ここでは不要
        // 必要に応じて他のタイマー処理を追加
    }
    
    func updateWorkoutData() {
        guard output.isWorkoutActive && !output.isPaused else { return }
        
        if let startTime = output.workoutStartTime {
            output.workoutDuration = Date().timeIntervalSince(startTime)
        }
        
        // レストタイマーの更新
        if output.restTimeRemaining > 0 {
            output.restTimeRemaining -= 1
        }
    }
    
    // MARK: - Actions
    func selectWorkoutType(_ type: HKWorkoutActivityType) {
        output.selectedWorkoutType = type
    }
    
    func startWorkout(type: HKWorkoutActivityType) {
        output.selectedWorkoutType = type
        output.isWorkoutActive = true
        output.isPaused = false
        output.workoutStartTime = Date()
        output.workoutDuration = 0
        output.currentSet = 1
        output.restTimeRemaining = 0
        
        healthKitManager.startWorkout(type: type)
    }
    
    func pauseWorkout() {
        output.isPaused.toggle()
    }
    
    func endWorkout() {
        output.isWorkoutActive = false
        output.isPaused = false
        output.workoutStartTime = nil
        output.workoutDuration = 0
        output.currentSet = 1
        output.restTimeRemaining = 0
        output.isVoiceGuided = false
        
        // 音声ガイド停止
        voiceManager.stopRestTimer()
        voiceManager.stopSpeaking()
        
        healthKitManager.endWorkout()
    }
    
    func recordSet(reps: Int, weight: Double) {
        guard reps > 0 && weight > 0 else { return }
        
        // セット記録の処理
        output.currentSet += 1
        
        // レストタイマー開始（90秒）
        output.restTimeRemaining = 90
        
        // 統計データの更新
        output.totalWeight += weight
        output.averageWeight = output.totalWeight / Double(output.currentSet - 1)
        
        // HealthKitにセットデータを記録
        healthKitManager.recordStrengthTrainingSet(
            reps: reps,
            weight: weight,
            exercise: "Strength Training"
        )
        
        print("セット記録: \(output.currentSet - 1)セット目 - \(reps)回 × \(weight)kg")
    }
    
    // MARK: - Voice Guided Workout
    
    func startVoiceGuidedWorkout(exercise: ExerciseType, sets: Int, reps: Int, weight: Double) {
        output.currentExercise = exercise
        output.totalSets = sets
        output.currentReps = reps
        output.currentWeight = weight
        output.currentSet = 1
        output.workoutDuration = 0
        output.isWorkoutActive = true
        output.isPaused = false
        output.isVoiceGuided = true
        output.workoutStartTime = Date()
        
        // HealthKitワークアウト開始
        healthKitManager.startWorkout(type: .traditionalStrengthTraining)
        
        // 音声ガイド開始
        voiceManager.announceExercise(exercise.displayName)
        
        // 準備時間（3秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.startVoiceGuidedSet()
        }
    }
    
    private func startVoiceGuidedSet() {
        guard output.isWorkoutActive && !output.isPaused && output.isVoiceGuided else { return }
        
        // セット開始の音声ガイド
        voiceManager.announceSetStart(setNumber: output.currentSet, totalSets: output.totalSets)
        
        // エクササイズ固有の音声ガイド
        switch output.currentExercise {
        case .dumbbellPress:
            voiceManager.announceDumbbellPress(setNumber: output.currentSet, reps: output.currentReps, weight: output.currentWeight)
        case .abs:
            voiceManager.announceAbsExercise(setNumber: output.currentSet, reps: output.currentReps)
        case .shoulderPress:
            voiceManager.announceShoulderExercise(setNumber: output.currentSet, reps: output.currentReps, weight: output.currentWeight)
        }
        
        // レップカウントダウン開始
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.voiceManager.startRepCountdown(from: self.output.currentReps)
        }
    }
    
    func completeSet() {
        guard output.isWorkoutActive else { return }
        
        if output.isVoiceGuided {
            // 音声ガイド付きセット完了
            voiceManager.announceSetComplete(setNumber: output.currentSet, reps: output.currentReps, weight: output.currentWeight)
            
            // HealthKitにセットデータを記録
            healthKitManager.recordStrengthTrainingSet(
                reps: output.currentReps,
                weight: output.currentWeight,
                exercise: output.currentExercise.displayName
            )
            
            output.currentSet += 1
            
            if output.currentSet > output.totalSets {
                // ワークアウト完了
                completeVoiceGuidedWorkout()
            } else {
                // 休憩開始
                startVoiceGuidedRest()
            }
        } else {
            // 通常のセット完了
            recordSet(reps: output.currentReps, weight: output.currentWeight)
        }
    }
    
    private func startVoiceGuidedRest() {
        output.restTimeRemaining = 60
        
        // 休憩タイマー開始（60秒）
        voiceManager.startRestTimer(seconds: 60)
        
        // 休憩終了後に次のセット開始
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            if self.output.isWorkoutActive && !self.output.isPaused && self.output.isVoiceGuided {
                self.startVoiceGuidedSet()
            }
        }
    }
    
    private func completeVoiceGuidedWorkout() {
        output.isWorkoutActive = false
        output.isVoiceGuided = false
        
        // ワークアウト完了の音声ガイド
        voiceManager.announceWorkoutComplete()
        
        // HealthKitワークアウト終了
        healthKitManager.endWorkout()
        
        // 3秒後にリセット
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.resetWorkout()
        }
    }
    
    private func resetWorkout() {
        output.currentSet = 1
        output.workoutDuration = 0
        output.restTimeRemaining = 0
        output.isVoiceGuided = false
        output.workoutStartTime = nil
    }
    
    func fetchRecentWorkouts() {
        healthKitManager.fetchRecentStrengthWorkouts { workouts in
            DispatchQueue.main.async {
                self.output.recentWorkouts = workouts
            }
        }
    }
    
    func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func refreshData() {
        fetchRecentWorkouts()
    }
    
    deinit {
        // TimerはView側で管理されるため、ここでは不要
    }
}

// MARK: - Supporting Types
extension HKWorkoutActivityType {
    var displayName: String {
        switch self {
        case .traditionalStrengthTraining:
            return "筋トレ"
        default:
            return "その他"
        }
    }
    
    var icon: String {
        switch self {
        case .traditionalStrengthTraining:
            return "dumbbell.fill"
        default:
            return "figure.mixed.cardio"
        }
    }
    
    var color: Color {
        switch self {
        case .traditionalStrengthTraining:
            return .orange
        default:
            return .gray
        }
    }
}

 