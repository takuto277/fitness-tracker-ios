import Foundation
import HealthKit
import SwiftUI

struct NutritionData {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sodium: Double
    let water: Double
    let date: Date
}

struct Meal: Identifiable {
    let id = UUID()
    let name: String
    let type: MealType
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let date: Date
    let notes: String?
}

enum MealType: String, CaseIterable {
    case breakfast = "朝食"
    case lunch = "昼食"
    case dinner = "夕食"
    case snack = "間食"
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise"
        case .lunch: return "sun.max"
        case .dinner: return "moon"
        case .snack: return "leaf"
        }
    }
}

class NutritionManager: ObservableObject {
    let healthStore = HKHealthStore()
    @Published var todayNutrition: NutritionData?
    @Published var weeklyNutrition: [NutritionData] = []
    @Published var meals: [Meal] = []
    @Published var dailyCalorieGoal: Double = 2000
    @Published var dailyProteinGoal: Double = 80
    @Published var dailyWaterGoal: Double = 2000
    
    init() {
        requestNutritionAuthorization()
    }
    
    private func requestNutritionAuthorization() {
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryFiber)!,
            HKQuantityType.quantityType(forIdentifier: .dietarySodium)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryFiber)!,
            HKQuantityType.quantityType(forIdentifier: .dietarySodium)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
            if success {
                print("栄養データ権限が許可されました")
                DispatchQueue.main.async {
                    self.fetchTodayNutrition()
                }
            } else {
                print("栄養データ権限エラー: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    func fetchTodayNutrition() {
        let startDate = Date().startOfDay
        let endDate = Date().endOfDay
        
        fetchNutritionData(startDate: startDate, endDate: endDate) { nutritionData in
            DispatchQueue.main.async {
                self.todayNutrition = nutritionData
            }
        }
    }
    
    private func fetchNutritionData(startDate: Date, endDate: Date, completion: @escaping (NutritionData) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let nutritionTypes: [HKQuantityTypeIdentifier: String] = [
            .dietaryEnergyConsumed: "calories",
            .dietaryProtein: "protein",
            .dietaryCarbohydrates: "carbs",
            .dietaryFatTotal: "fat",
            .dietaryFiber: "fiber",
            .dietarySodium: "sodium",
            .dietaryWater: "water"
        ]
        
        var nutritionValues: [String: Double] = [:]
        let group = DispatchGroup()
        
        for (typeIdentifier, key) in nutritionTypes {
            group.enter()
            
            guard let quantityType = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else {
                group.leave()
                continue
            }
            
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                defer { group.leave() }
                
                if let sum = result?.sumQuantity() {
                    let value: Double
                    switch typeIdentifier {
                    case .dietaryEnergyConsumed:
                        value = sum.doubleValue(for: HKUnit.kilocalorie())
                    case .dietaryProtein, .dietaryCarbohydrates, .dietaryFatTotal:
                        value = sum.doubleValue(for: HKUnit.gram())
                    case .dietaryFiber:
                        value = sum.doubleValue(for: HKUnit.gram())
                    case .dietarySodium:
                        value = sum.doubleValue(for: HKUnit.gramUnit(with: .milli))
                    case .dietaryWater:
                        value = sum.doubleValue(for: HKUnit.literUnit(with: .milli))
                    default:
                        value = 0
                    }
                    nutritionValues[key] = value
                }
            }
            
            healthStore.execute(query)
        }
        
        group.notify(queue: .main) {
            let nutritionData = NutritionData(
                calories: nutritionValues["calories"] ?? 0,
                protein: nutritionValues["protein"] ?? 0,
                carbs: nutritionValues["carbs"] ?? 0,
                fat: nutritionValues["fat"] ?? 0,
                fiber: nutritionValues["fiber"] ?? 0,
                sodium: nutritionValues["sodium"] ?? 0,
                water: nutritionValues["water"] ?? 0,
                date: startDate
            )
            completion(nutritionData)
        }
    }
    
    func addMeal(_ meal: Meal) {
        meals.append(meal)
        saveMealToHealthKit(meal)
    }
    
    private func saveMealToHealthKit(_ meal: Meal) {
        // カロリー
        if meal.calories > 0 {
            let calorieType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
            let calorieQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: meal.calories)
            let calorieSample = HKQuantitySample(type: calorieType, quantity: calorieQuantity, start: meal.date, end: meal.date)
            healthStore.save(calorieSample) { success, error in
                if !success {
                    print("カロリー保存エラー: \(error?.localizedDescription ?? "")")
                }
            }
        }
        
        // タンパク質
        if meal.protein > 0 {
            let proteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!
            let proteinQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: meal.protein)
            let proteinSample = HKQuantitySample(type: proteinType, quantity: proteinQuantity, start: meal.date, end: meal.date)
            healthStore.save(proteinSample) { success, error in
                if !success {
                    print("タンパク質保存エラー: \(error?.localizedDescription ?? "")")
                }
            }
        }
        
        // 炭水化物
        if meal.carbs > 0 {
            let carbsType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!
            let carbsQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: meal.carbs)
            let carbsSample = HKQuantitySample(type: carbsType, quantity: carbsQuantity, start: meal.date, end: meal.date)
            healthStore.save(carbsSample) { success, error in
                if !success {
                    print("炭水化物保存エラー: \(error?.localizedDescription ?? "")")
                }
            }
        }
        
        // 脂質
        if meal.fat > 0 {
            let fatType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!
            let fatQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: meal.fat)
            let fatSample = HKQuantitySample(type: fatType, quantity: fatQuantity, start: meal.date, end: meal.date)
            healthStore.save(fatSample) { success, error in
                if !success {
                    print("脂質保存エラー: \(error?.localizedDescription ?? "")")
                }
            }
        }
    }
    
    func getCalorieProgress() -> Double {
        guard let today = todayNutrition else { return 0 }
        return min(today.calories / dailyCalorieGoal, 1.0)
    }
    
    func getProteinProgress() -> Double {
        guard let today = todayNutrition else { return 0 }
        return min(today.protein / dailyProteinGoal, 1.0)
    }
    
    func getWaterProgress() -> Double {
        guard let today = todayNutrition else { return 0 }
        return min(today.water / dailyWaterGoal, 1.0)
    }
} 