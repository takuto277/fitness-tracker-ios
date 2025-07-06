import SwiftUI
import HealthKit
import Combine

// MARK: - Output
struct RealTimeWorkoutOutput {
    var selectedWorkoutType: HKWorkoutActivityType = .traditionalStrengthTraining
    var isWorkoutActive: Bool = false
    var workoutStartTime: Date?
    var currentHeartRate: Double = 0
    var currentCalories: Double = 0
    var workoutDuration: TimeInterval = 0
    var currentSet: Int = 0
    var currentReps: Int = 0
    var currentWeight: Double = 0
    var restTime: TimeInterval = 0
    var isAuthorized: Bool = false
    var isLoading: Bool = false
}

// MARK: - ViewModel
@MainActor
class RealTimeWorkoutViewModel: ObservableObject {
    @Published var output = RealTimeWorkoutOutput()
    
    private let healthKitManager: HealthKitManager
    private var cancellables = Set<AnyCancellable>()
    // TimerはView側でonReceiveを使用するため、ここでは不要
    
    // 利用可能なワークアウトタイプ
    static let availableWorkoutTypes: [HKWorkoutActivityType] = [
        .traditionalStrengthTraining,
        .running,
        .cycling,
        .walking,
        .swimming
    ]
    
    init(healthKitManager: HealthKitManager) {
        self.healthKitManager = healthKitManager
        setupBindings()
        setupTimer()
    }
    
    private func setupBindings() {
        // HealthKitManagerのデータ変更を監視
        healthKitManager.$isWorkoutActive
            .assign(to: \.output.isWorkoutActive, on: self)
            .store(in: &cancellables)
        
        healthKitManager.$heartRate
            .assign(to: \.output.currentHeartRate, on: self)
            .store(in: &cancellables)
        
        healthKitManager.$activeEnergy
            .assign(to: \.output.currentCalories, on: self)
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
        guard output.isWorkoutActive else { return }
        
        if let startTime = output.workoutStartTime {
            output.workoutDuration = Date().timeIntervalSince(startTime)
        }
        
        // レストタイマーの更新
        if output.restTime > 0 {
            output.restTime -= 1
        }
    }
    
    // MARK: - Actions
    func selectWorkoutType(_ type: HKWorkoutActivityType) {
        output.selectedWorkoutType = type
    }
    
    func startWorkout() {
        output.isWorkoutActive = true
        output.workoutStartTime = Date()
        output.workoutDuration = 0
        output.currentCalories = 0
        
        healthKitManager.startWorkout(type: output.selectedWorkoutType)
    }
    
    func stopWorkout() {
        output.isWorkoutActive = false
        output.workoutStartTime = nil
        output.workoutDuration = 0
        
        healthKitManager.endWorkout()
    }
    
    func recordSet() {
        guard output.currentReps > 0 && output.currentWeight > 0 else { return }
        
        // セット記録の処理
        output.currentSet += 1
        
        // レストタイマー開始（90秒）
        output.restTime = 90
        
        // 実際のアプリでは、セットデータを保存
        print("セット記録: \(output.currentSet)セット目 - \(output.currentReps)回 × \(output.currentWeight)kg")
    }
    
    func updateReps(_ reps: Int) {
        output.currentReps = reps
    }
    
    func updateWeight(_ weight: Double) {
        output.currentWeight = weight
    }
    
    func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
        case .running:
            return "ランニング"
        case .cycling:
            return "サイクリング"
        case .walking:
            return "ウォーキング"
        case .swimming:
            return "スイミング"
        default:
            return "その他"
        }
    }
    
    var icon: String {
        switch self {
        case .traditionalStrengthTraining:
            return "dumbbell.fill"
        case .running:
            return "figure.run"
        case .cycling:
            return "bicycle"
        case .walking:
            return "figure.walk"
        case .swimming:
            return "figure.pool.swim"
        default:
            return "figure.mixed.cardio"
        }
    }
    
    var color: Color {
        switch self {
        case .traditionalStrengthTraining:
            return .orange
        case .running:
            return .green
        case .cycling:
            return .blue
        case .walking:
            return .purple
        case .swimming:
            return .cyan
        default:
            return .gray
        }
    }
}

 