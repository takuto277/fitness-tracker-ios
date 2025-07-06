import SwiftUI
import HealthKit
import Combine

@MainActor
class DebugViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var workoutCount = 0
    @Published var totalWorkoutDuration: TimeInterval = 0
    @Published var totalCalories: Double = 0
    @Published var averageHeartRate: Double = 0
    @Published var workouts: [HKWorkout] = []
    @Published var heartRateData: [HKQuantitySample] = []
    @Published var calorieData: [HKQuantitySample] = []
    @Published var lastFetchTime = ""
    @Published var totalDataCount = 0
    @Published var errorCount = 0
    
    private let healthKitManager = HealthKitManager()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // HealthKitManagerの認証状態を監視
        healthKitManager.$isAuthorized
            .sink { [weak self] isAuthorized in
                if isAuthorized {
                    print("HealthKit認証済み - デバッグデータ読み込み可能")
                } else {
                    print("HealthKit未認証 - デバッグデータ読み込み不可")
                }
            }
            .store(in: &cancellables)
    }
    
    func loadData(for date: Date) {
        isLoading = true
        lastFetchTime = DateUtil.shared.formatJapaneseDateTime(Date())
        
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await self.fetchWorkouts(for: date)
                }
                
                group.addTask {
                    await self.fetchHeartRateData(for: date)
                }
                
                group.addTask {
                    await self.fetchCalorieData(for: date)
                }
            }
            
            await MainActor.run {
                self.calculateSummary()
                self.isLoading = false
            }
        }
    }
    
    private func fetchWorkouts(for date: Date) async {
        let startDate = Calendar.current.startOfDay(for: date)
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate
        
        do {
            let workouts = await healthKitManager.fetchWorkouts(from: startDate, to: endDate)
            let strengthWorkouts = workouts.filter { $0.workoutActivityType == .traditionalStrengthTraining }
            
            await MainActor.run {
                self.workouts = strengthWorkouts
                print("取得した筋トレデータ: \(strengthWorkouts.count)件")
            }
        } catch {
            await MainActor.run {
                self.errorCount += 1
                print("筋トレデータ取得エラー: \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchHeartRateData(for date: Date) async {
        let startDate = Calendar.current.startOfDay(for: date)
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate
        
        await withCheckedContinuation { continuation in
            let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            
            let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    print("心拍数データ取得エラー: \(error.localizedDescription)")
                    Task { @MainActor in
                        self.errorCount += 1
                    }
                    continuation.resume()
                    return
                }
                
                let heartRateSamples = samples as? [HKQuantitySample] ?? []
                print("取得した心拍数データ: \(heartRateSamples.count)件")
                
                Task { @MainActor in
                    self.heartRateData = heartRateSamples
                }
                
                continuation.resume()
            }
            
            healthKitManager.healthStore.execute(query)
        }
    }
    
    private func fetchCalorieData(for date: Date) async {
        let startDate = Calendar.current.startOfDay(for: date)
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate
        
        await withCheckedContinuation { continuation in
            let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            
            let query = HKSampleQuery(sampleType: calorieType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    print("カロリーデータ取得エラー: \(error.localizedDescription)")
                    Task { @MainActor in
                        self.errorCount += 1
                    }
                    continuation.resume()
                    return
                }
                
                let calorieSamples = samples as? [HKQuantitySample] ?? []
                print("取得したカロリーデータ: \(calorieSamples.count)件")
                
                Task { @MainActor in
                    self.calorieData = calorieSamples
                }
                
                continuation.resume()
            }
            
            healthKitManager.healthStore.execute(query)
        }
    }
    
    private func calculateSummary() {
        // 筋トレデータの集計
        workoutCount = workouts.count
        totalWorkoutDuration = workouts.reduce(0) { $0 + $1.duration }
        
        // カロリーデータの集計
        totalCalories = calorieData.reduce(0) { $0 + $1.quantity.doubleValue(for: .kilocalorie()) }
        
        // 心拍数データの集計
        let heartRates = heartRateData.map { $0.quantity.doubleValue(for: HKUnit(from: "count/min")) }
        averageHeartRate = heartRates.isEmpty ? 0 : heartRates.reduce(0, +) / Double(heartRates.count)
        
        // 総データ件数
        totalDataCount = workouts.count + heartRateData.count + calorieData.count
        
        print("データサマリー計算完了:")
        print("- 筋トレ回数: \(workoutCount)")
        print("- 総時間: \(Int(totalWorkoutDuration / 60))分")
        print("- 総カロリー: \(Int(totalCalories))kcal")
        print("- 平均心拍数: \(Int(averageHeartRate))BPM")
        print("- 総データ件数: \(totalDataCount)")
    }
    
    func refreshData() {
        loadData(for: Date())
    }
    
    func clearData() {
        workouts = []
        heartRateData = []
        calorieData = []
        workoutCount = 0
        totalWorkoutDuration = 0
        totalCalories = 0
        averageHeartRate = 0
        totalDataCount = 0
        errorCount = 0
        lastFetchTime = ""
    }
} 