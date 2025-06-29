import Foundation
import HealthKit

class ProgressManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var overallProgress: Double = 0.0
    @Published var weightProgress: Double = 0.0
    @Published var muscleProgress: Double = 0.0
    @Published var fitnessProgress: Double = 0.0
    @Published var nutritionProgress: Double = 0.0
    
    @Published var weeklyData: [ProgressData] = []
    @Published var monthlyData: [ProgressData] = []
    
    init() {
        calculateProgress()
    }
    
    func calculateProgress() {
        calculateWeightProgress()
        calculateMuscleProgress()
        calculateFitnessProgress()
        calculateNutritionProgress()
        calculateOverallProgress()
    }
    
    private func calculateWeightProgress() {
        // 体重の進捗を計算（目標体重への進捗）
        // 実際のアプリでは目標設定から計算
        weightProgress = 0.6 // 仮の値
    }
    
    private func calculateMuscleProgress() {
        // 筋肉量の進捗を計算
        muscleProgress = 0.7 // 仮の値
    }
    
    private func calculateFitnessProgress() {
        // フィットネスの進捗を計算（運動時間、心拍数など）
        fitnessProgress = 0.8 // 仮の値
    }
    
    private func calculateNutritionProgress() {
        // 栄養の進捗を計算（カロリーバランス、栄養素など）
        nutritionProgress = 0.5 // 仮の値
    }
    
    private func calculateOverallProgress() {
        // 全体の進捗を計算
        overallProgress = (weightProgress + muscleProgress + fitnessProgress + nutritionProgress) / 4.0
    }
    
    func fetchWeeklyData() {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        
        fetchProgressData(from: startDate, to: endDate) { data in
            DispatchQueue.main.async {
                self.weeklyData = data
            }
        }
    }
    
    func fetchMonthlyData() {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .month, value: -1, to: endDate)!
        
        fetchProgressData(from: startDate, to: endDate) { data in
            DispatchQueue.main.async {
                self.monthlyData = data
            }
        }
    }
    
    private func fetchProgressData(from startDate: Date, to endDate: Date, completion: @escaping ([ProgressData]) -> Void) {
        var progressData: [ProgressData] = []
        let calendar = Calendar.current
        
        // 日付ごとのデータを取得
        var currentDate = startDate
        while currentDate <= endDate {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            fetchDailyProgressData(for: dayStart) { dailyData in
                progressData.append(dailyData)
                
                // 全ての日付のデータが取得できたら完了
                if progressData.count == calendar.dateComponents([.day], from: startDate, to: endDate).day! + 1 {
                    completion(progressData.sorted { $0.date < $1.date })
                }
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
    }
    
    private func fetchDailyProgressData(for date: Date, completion: @escaping (ProgressData) -> Void) {
        let calendar = Calendar.current
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: date)!
        
        // 体重データ
        fetchWeightData(from: date, to: dayEnd) { weight in
            // 筋肉量データ
            self.fetchMuscleMassData(from: date, to: dayEnd) { muscleMass in
                // 運動データ
                self.fetchWorkoutData(from: date, to: dayEnd) { workoutDuration, calories in
                    // 栄養データ
                    self.fetchNutritionData(from: date, to: dayEnd) { nutritionCalories in
                        let progressData = ProgressData(
                            date: date,
                            weight: weight,
                            muscleMass: muscleMass,
                            workoutDuration: workoutDuration,
                            caloriesBurned: calories,
                            caloriesConsumed: nutritionCalories
                        )
                        completion(progressData)
                    }
                }
            }
        }
    }
    
    private func fetchWeightData(from startDate: Date, to endDate: Date, completion: @escaping (Double) -> Void) {
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let sample = samples?.first as? HKQuantitySample {
                let weight = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                completion(weight)
            } else {
                completion(0.0)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchMuscleMassData(from startDate: Date, to endDate: Date, completion: @escaping (Double) -> Void) {
        let muscleMassType = HKQuantityType.quantityType(forIdentifier: .leanBodyMass)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: muscleMassType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let sample = samples?.first as? HKQuantitySample {
                let muscleMass = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                completion(muscleMass)
            } else {
                completion(0.0)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchWorkoutData(from startDate: Date, to endDate: Date, completion: @escaping (TimeInterval, Double) -> Void) {
        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            var totalDuration: TimeInterval = 0
            var totalCalories: Double = 0
            
            if let workouts = samples as? [HKWorkout] {
                for workout in workouts {
                    totalDuration += workout.duration
                    if let calories = workout.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) {
                        totalCalories += calories
                    }
                }
            }
            
            completion(totalDuration, totalCalories)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchNutritionData(from startDate: Date, to endDate: Date, completion: @escaping (Double) -> Void) {
        let calorieType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if let sum = result?.sumQuantity() {
                let calories = sum.doubleValue(for: HKUnit.kilocalorie())
                completion(calories)
            } else {
                completion(0.0)
            }
        }
        
        healthStore.execute(query)
    }
}

// 進捗データ構造
struct ProgressData: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
    let muscleMass: Double
    let workoutDuration: TimeInterval
    let caloriesBurned: Double
    let caloriesConsumed: Double
    
    var weightChange: Double {
        // 前日との比較（実際のアプリでは前日データを取得）
        return 0.0
    }
    
    var muscleMassChange: Double {
        // 前日との比較
        return 0.0
    }
    
    var calorieBalance: Double {
        return caloriesConsumed - caloriesBurned
    }
} 