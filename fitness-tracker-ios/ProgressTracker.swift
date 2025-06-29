import Foundation
import HealthKit
import SwiftUI

struct ProgressData {
    let date: Date
    let weight: Double?
    let bodyFatPercentage: Double?
    let muscleMass: Double?
    let bodyMassIndex: Double?
    let activeEnergy: Double
    let workoutMinutes: Double
    let strengthWorkoutMinutes: Double
}

class ProgressTracker: ObservableObject {
    let healthStore = HKHealthStore()
    @Published var progressData: [ProgressData] = []
    @Published var weeklyProgress: ProgressData?
    @Published var monthlyProgress: ProgressData?
    
    // 目標設定
    @Published var targetWeight: Double = 0
    @Published var targetBodyFatPercentage: Double = 0
    @Published var targetMuscleMass: Double = 0
    @Published var weeklyWorkoutGoal: Double = 150 // 分
    @Published var weeklyStrengthGoal: Double = 90 // 分
    
    init() {
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!,
            HKQuantityType.quantityType(forIdentifier: .leanBodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .bodyMassIndex)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.workoutType()
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                print("進捗トラッカー権限が許可されました")
                DispatchQueue.main.async {
                    self.fetchProgressData()
                }
            } else {
                print("進捗トラッカー権限エラー: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    func fetchProgressData() {
        let calendar = Calendar.current
        let now = Date()
        
        // 過去30日間のデータを取得
        let startDate = calendar.date(byAdding: .day, value: -30, to: now)!
        
        fetchWeightData(startDate: startDate, endDate: now)
        fetchBodyCompositionData(startDate: startDate, endDate: now)
        fetchActivityData(startDate: startDate, endDate: now)
    }
    
    private func fetchWeightData(startDate: Date, endDate: Date) {
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: 30, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let weightSamples = samples as? [HKQuantitySample] {
                DispatchQueue.main.async {
                    self.processWeightData(weightSamples)
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchBodyCompositionData(startDate: Date, endDate: Date) {
        // 体脂肪率
        let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!
        let bodyFatPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let bodyFatQuery = HKSampleQuery(sampleType: bodyFatType, predicate: bodyFatPredicate, limit: 30, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]) { _, samples, error in
            if let bodyFatSamples = samples as? [HKQuantitySample] {
                DispatchQueue.main.async {
                    self.processBodyFatData(bodyFatSamples)
                }
            }
        }
        
        // 筋肉量
        let muscleType = HKQuantityType.quantityType(forIdentifier: .leanBodyMass)!
        let musclePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let muscleQuery = HKSampleQuery(sampleType: muscleType, predicate: musclePredicate, limit: 30, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]) { _, samples, error in
            if let muscleSamples = samples as? [HKQuantitySample] {
                DispatchQueue.main.async {
                    self.processMuscleData(muscleSamples)
                }
            }
        }
        
        healthStore.execute(bodyFatQuery)
        healthStore.execute(muscleQuery)
    }
    
    private func fetchActivityData(startDate: Date, endDate: Date) {
        // アクティブエネルギー
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let energyPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let energyQuery = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: energyPredicate, options: .cumulativeSum) { _, result, _ in
            if let sum = result?.sumQuantity() {
                let energy = sum.doubleValue(for: HKUnit.kilocalorie())
                DispatchQueue.main.async {
                    self.processActivityData(energy: energy)
                }
            }
        }
        
        // ワークアウトデータ
        let workoutType = HKObjectType.workoutType()
        let workoutPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let workoutQuery = HKSampleQuery(sampleType: workoutType, predicate: workoutPredicate, limit: 50, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]) { _, samples, _ in
            if let workoutSamples = samples as? [HKWorkout] {
                DispatchQueue.main.async {
                    self.processWorkoutData(workouts: workoutSamples)
                }
            }
        }
        
        healthStore.execute(energyQuery)
        healthStore.execute(workoutQuery)
    }
    
    private func processWeightData(_ samples: [HKQuantitySample]) {
        for sample in samples {
            let weight = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            let date = sample.endDate
            
            if let index = progressData.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                progressData[index] = ProgressData(
                    date: progressData[index].date,
                    weight: weight,
                    bodyFatPercentage: progressData[index].bodyFatPercentage,
                    muscleMass: progressData[index].muscleMass,
                    bodyMassIndex: progressData[index].bodyMassIndex,
                    activeEnergy: progressData[index].activeEnergy,
                    workoutMinutes: progressData[index].workoutMinutes,
                    strengthWorkoutMinutes: progressData[index].strengthWorkoutMinutes
                )
            } else {
                progressData.append(ProgressData(
                    date: date,
                    weight: weight,
                    bodyFatPercentage: nil,
                    muscleMass: nil,
                    bodyMassIndex: nil,
                    activeEnergy: 0,
                    workoutMinutes: 0,
                    strengthWorkoutMinutes: 0
                ))
            }
        }
        
        progressData.sort { $0.date < $1.date }
    }
    
    private func processBodyFatData(_ samples: [HKQuantitySample]) {
        for sample in samples {
            let bodyFat = sample.quantity.doubleValue(for: HKUnit.percent())
            let date = sample.endDate
            
            if let index = progressData.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                progressData[index] = ProgressData(
                    date: progressData[index].date,
                    weight: progressData[index].weight,
                    bodyFatPercentage: bodyFat,
                    muscleMass: progressData[index].muscleMass,
                    bodyMassIndex: progressData[index].bodyMassIndex,
                    activeEnergy: progressData[index].activeEnergy,
                    workoutMinutes: progressData[index].workoutMinutes,
                    strengthWorkoutMinutes: progressData[index].strengthWorkoutMinutes
                )
            }
        }
    }
    
    private func processMuscleData(_ samples: [HKQuantitySample]) {
        for sample in samples {
            let muscle = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            let date = sample.endDate
            
            if let index = progressData.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                progressData[index] = ProgressData(
                    date: progressData[index].date,
                    weight: progressData[index].weight,
                    bodyFatPercentage: progressData[index].bodyFatPercentage,
                    muscleMass: muscle,
                    bodyMassIndex: progressData[index].bodyMassIndex,
                    activeEnergy: progressData[index].activeEnergy,
                    workoutMinutes: progressData[index].workoutMinutes,
                    strengthWorkoutMinutes: progressData[index].strengthWorkoutMinutes
                )
            }
        }
    }
    
    private func processActivityData(energy: Double) {
        // 週間・月間のアクティビティデータを更新
        let weeklyData = progressData.filter { 
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) 
        }
        
        let monthlyData = progressData.filter { 
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) 
        }
        
        // 週間データの更新
        if let lastWeekly = weeklyData.last {
            weeklyProgress = ProgressData(
                date: lastWeekly.date,
                weight: lastWeekly.weight,
                bodyFatPercentage: lastWeekly.bodyFatPercentage,
                muscleMass: lastWeekly.muscleMass,
                bodyMassIndex: lastWeekly.bodyMassIndex,
                activeEnergy: energy,
                workoutMinutes: lastWeekly.workoutMinutes,
                strengthWorkoutMinutes: lastWeekly.strengthWorkoutMinutes
            )
        }
    }
    
    private func processWorkoutData(workouts: [HKWorkout]) {
        let calendar = Calendar.current
        let now = Date()
        
        // 週間のワークアウト時間
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let weeklyWorkouts = workouts.filter { $0.endDate >= weekStart }
        let weeklyMinutes = weeklyWorkouts.reduce(0) { $0 + $1.duration / 60 }
        
        // 週間の筋トレ時間
        let weeklyStrengthWorkouts = weeklyWorkouts.filter { 
            $0.workoutActivityType == .functionalStrengthTraining || 
            $0.workoutActivityType == .traditionalStrengthTraining ||
            $0.workoutActivityType == .coreTraining
        }
        let weeklyStrengthMinutes = weeklyStrengthWorkouts.reduce(0) { $0 + $1.duration / 60 }
        
        // 月間のワークアウト時間
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let monthlyWorkouts = workouts.filter { $0.endDate >= monthStart }
        let monthlyMinutes = monthlyWorkouts.reduce(0) { $0 + $1.duration / 60 }
        
        // 月間の筋トレ時間
        let monthlyStrengthWorkouts = monthlyWorkouts.filter { 
            $0.workoutActivityType == .functionalStrengthTraining || 
            $0.workoutActivityType == .traditionalStrengthTraining ||
            $0.workoutActivityType == .coreTraining
        }
        let monthlyStrengthMinutes = monthlyStrengthWorkouts.reduce(0) { $0 + $1.duration / 60 }
        
        // 進捗データを更新
        if let lastData = progressData.last {
            progressData[progressData.count - 1] = ProgressData(
                date: lastData.date,
                weight: lastData.weight,
                bodyFatPercentage: lastData.bodyFatPercentage,
                muscleMass: lastData.muscleMass,
                bodyMassIndex: lastData.bodyMassIndex,
                activeEnergy: lastData.activeEnergy,
                workoutMinutes: weeklyMinutes,
                strengthWorkoutMinutes: weeklyStrengthMinutes
            )
        }
        
        // 週間・月間データを更新
        weeklyProgress = ProgressData(
            date: now,
            weight: progressData.last?.weight,
            bodyFatPercentage: progressData.last?.bodyFatPercentage,
            muscleMass: progressData.last?.muscleMass,
            bodyMassIndex: progressData.last?.bodyMassIndex,
            activeEnergy: 0,
            workoutMinutes: weeklyMinutes,
            strengthWorkoutMinutes: weeklyStrengthMinutes
        )
        
        monthlyProgress = ProgressData(
            date: now,
            weight: progressData.last?.weight,
            bodyFatPercentage: progressData.last?.bodyFatPercentage,
            muscleMass: progressData.last?.muscleMass,
            bodyMassIndex: progressData.last?.bodyMassIndex,
            activeEnergy: 0,
            workoutMinutes: monthlyMinutes,
            strengthWorkoutMinutes: monthlyStrengthMinutes
        )
    }
    
    // 進捗分析メソッド
    func getWeightProgress() -> Double {
        guard let currentWeight = progressData.last?.weight,
              targetWeight > 0 else { return 0 }
        
        let initialWeight = progressData.first?.weight ?? currentWeight
        let totalChange = initialWeight - targetWeight
        let currentChange = initialWeight - currentWeight
        
        return totalChange > 0 ? min(currentChange / totalChange, 1.0) : 0
    }
    
    func getMuscleGainProgress() -> Double {
        guard let currentMuscle = progressData.last?.muscleMass,
              targetMuscleMass > 0 else { return 0 }
        
        let initialMuscle = progressData.first?.muscleMass ?? currentMuscle
        let totalChange = targetMuscleMass - initialMuscle
        let currentChange = currentMuscle - initialMuscle
        
        return totalChange > 0 ? min(currentChange / totalChange, 1.0) : 0
    }
    
    func getWorkoutProgress() -> Double {
        guard let weekly = weeklyProgress else { return 0 }
        return min(weekly.workoutMinutes / weeklyWorkoutGoal, 1.0)
    }
    
    func getStrengthProgress() -> Double {
        guard let weekly = weeklyProgress else { return 0 }
        return min(weekly.strengthWorkoutMinutes / weeklyStrengthGoal, 1.0)
    }
    
    func getOverallProgress() -> Double {
        let weightProgress = getWeightProgress()
        let muscleProgress = getMuscleGainProgress()
        let workoutProgress = getWorkoutProgress()
        let strengthProgress = getStrengthProgress()
        
        return (weightProgress + muscleProgress + workoutProgress + strengthProgress) / 4.0
    }
    
    // 進捗サマリー
    func getProgressSummary() -> String {
        var summary = "=== 進捗サマリー ===\n"
        
        if let currentWeight = progressData.last?.weight,
           let initialWeight = progressData.first?.weight {
            let weightChange = currentWeight - initialWeight
            summary += "体重変化: \(String(format: "%.1f", weightChange))kg\n"
        }
        
        if let currentMuscle = progressData.last?.muscleMass,
           let initialMuscle = progressData.first?.muscleMass {
            let muscleChange = currentMuscle - initialMuscle
            summary += "筋肉量変化: \(String(format: "%.1f", muscleChange))kg\n"
        }
        
        if let weekly = weeklyProgress {
            summary += "週間運動時間: \(Int(weekly.workoutMinutes))分\n"
            summary += "週間筋トレ時間: \(Int(weekly.strengthWorkoutMinutes))分\n"
        }
        
        summary += "全体進捗: \(Int(getOverallProgress() * 100))%\n"
        summary += "=================="
        
        return summary
    }
} 