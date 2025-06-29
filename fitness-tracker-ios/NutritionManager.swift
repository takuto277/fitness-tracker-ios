import Foundation
import HealthKit

class NutritionManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var todayCalories: Double = 0
    @Published var todayProtein: Double = 0
    @Published var todayCarbs: Double = 0
    @Published var todayFat: Double = 0
    @Published var todayWater: Double = 0
    
    init() {
        fetchTodayNutritionData()
    }
    
    func fetchTodayNutritionData() {
        fetchCalories()
        fetchProtein()
        fetchCarbs()
        fetchFat()
        fetchWater()
    }
    
    private func fetchCalories() {
        let calorieType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        let predicate = HKQuery.predicateForSamples(withStart: Date().startOfDay, end: Date().endOfDay, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if let sum = result?.sumQuantity() {
                let calories = sum.doubleValue(for: HKUnit.kilocalorie())
                DispatchQueue.main.async {
                    self.todayCalories = calories
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchProtein() {
        let proteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!
        let predicate = HKQuery.predicateForSamples(withStart: Date().startOfDay, end: Date().endOfDay, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: proteinType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if let sum = result?.sumQuantity() {
                let protein = sum.doubleValue(for: HKUnit.gram())
                DispatchQueue.main.async {
                    self.todayProtein = protein
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchCarbs() {
        let carbsType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!
        let predicate = HKQuery.predicateForSamples(withStart: Date().startOfDay, end: Date().endOfDay, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: carbsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if let sum = result?.sumQuantity() {
                let carbs = sum.doubleValue(for: HKUnit.gram())
                DispatchQueue.main.async {
                    self.todayCarbs = carbs
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchFat() {
        let fatType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!
        let predicate = HKQuery.predicateForSamples(withStart: Date().startOfDay, end: Date().endOfDay, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: fatType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if let sum = result?.sumQuantity() {
                let fat = sum.doubleValue(for: HKUnit.gram())
                DispatchQueue.main.async {
                    self.todayFat = fat
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchWater() {
        let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
        let predicate = HKQuery.predicateForSamples(withStart: Date().startOfDay, end: Date().endOfDay, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: waterType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if let sum = result?.sumQuantity() {
                let water = sum.doubleValue(for: HKUnit.liter())
                DispatchQueue.main.async {
                    self.todayWater = water
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    func addNutritionData(calories: Double, protein: Double, carbs: Double, fat: Double) {
        let now = Date()
        
        // カロリー
        if calories > 0 {
            let calorieType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
            let calorieQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: calories)
            let calorieSample = HKQuantitySample(type: calorieType, quantity: calorieQuantity, start: now, end: now)
            healthStore.save(calorieSample) { _, _ in }
        }
        
        // タンパク質
        if protein > 0 {
            let proteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!
            let proteinQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: protein)
            let proteinSample = HKQuantitySample(type: proteinType, quantity: proteinQuantity, start: now, end: now)
            healthStore.save(proteinSample) { _, _ in }
        }
        
        // 炭水化物
        if carbs > 0 {
            let carbsType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!
            let carbsQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: carbs)
            let carbsSample = HKQuantitySample(type: carbsType, quantity: carbsQuantity, start: now, end: now)
            healthStore.save(carbsSample) { _, _ in }
        }
        
        // 脂質
        if fat > 0 {
            let fatType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!
            let fatQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: fat)
            let fatSample = HKQuantitySample(type: fatType, quantity: fatQuantity, start: now, end: now)
            healthStore.save(fatSample) { _, _ in }
        }
        
        // データを更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.fetchTodayNutritionData()
        }
    }
} 