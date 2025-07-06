import SwiftUI
import HealthKit
import Combine

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
    private var cancellables = Set<AnyCancellable>()
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

 