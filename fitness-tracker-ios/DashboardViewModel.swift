import SwiftUI
import HealthKit
import Combine

// MARK: - Output
struct DashboardOutput {
    var stepCount: Int = 0
    var heartRate: Double = 0
    var activeEnergy: Double = 0
    var distance: Double = 0
    var currentWeight: Double = 0
    var currentMuscleMass: Double = 0
    var currentBodyFatPercentage: Double = 0
    var currentBasalMetabolicRate: Double = 0
    var overallProgress: Double = 0
    var isWorkoutActive: Bool = false
    var currentDate: String = ""
    var isLoading: Bool = false
}

// MARK: - ViewModel
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var output = DashboardOutput()
    
    private let healthKitManager: HealthKitManager
    private let bodyCompositionManager: BodyCompositionManager
    private let progressManager: ProgressManager
    private var cancellables = Set<AnyCancellable>()
    
    init(
        healthKitManager: HealthKitManager,
        bodyCompositionManager: BodyCompositionManager,
        progressManager: ProgressManager
    ) {
        self.healthKitManager = healthKitManager
        self.bodyCompositionManager = bodyCompositionManager
        self.progressManager = progressManager
        
        setupBindings()
        updateCurrentDate()
    }
    
    private func setupBindings() {
        // HealthKitManagerのデータ変更を監視
        healthKitManager.$stepCount
            .assign(to: \.output.stepCount, on: self)
            .store(in: &cancellables)
        
        healthKitManager.$heartRate
            .assign(to: \.output.heartRate, on: self)
            .store(in: &cancellables)
        
        healthKitManager.$activeEnergy
            .assign(to: \.output.activeEnergy, on: self)
            .store(in: &cancellables)
        
        healthKitManager.$distance
            .assign(to: \.output.distance, on: self)
            .store(in: &cancellables)
        
        healthKitManager.$isWorkoutActive
            .assign(to: \.output.isWorkoutActive, on: self)
            .store(in: &cancellables)
        
        // BodyCompositionManagerのデータ変更を監視
        bodyCompositionManager.$currentWeight
            .assign(to: \.output.currentWeight, on: self)
            .store(in: &cancellables)
        
        bodyCompositionManager.$currentMuscleMass
            .assign(to: \.output.currentMuscleMass, on: self)
            .store(in: &cancellables)
        
        bodyCompositionManager.$currentBodyFatPercentage
            .assign(to: \.output.currentBodyFatPercentage, on: self)
            .store(in: &cancellables)
        
        bodyCompositionManager.$currentBasalMetabolicRate
            .assign(to: \.output.currentBasalMetabolicRate, on: self)
            .store(in: &cancellables)
        
        // ProgressManagerのデータ変更を監視
        progressManager.$overallProgress
            .assign(to: \.output.overallProgress, on: self)
            .store(in: &cancellables)
    }
    
    private func updateCurrentDate() {
        output.currentDate = DateUtil.shared.formatJapaneseDate(Date())
    }
    
    // MARK: - Actions
    func refreshData() async {
        output.isLoading = true
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.healthKitManager.fetchTodayData()
            }
            
            group.addTask {
                await self.bodyCompositionManager.fetchLatestBodyCompositionData()
            }
            
            group.addTask {
                await self.progressManager.calculateProgress()
            }
        }
        
        output.isLoading = false
    }
    
    func endWorkout() {
        healthKitManager.endWorkout()
    }
    
    func startWorkout() {
        // 運動開始の処理
        // 必要に応じて実装
    }
} 