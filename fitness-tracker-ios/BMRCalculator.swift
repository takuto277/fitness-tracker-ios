import Foundation
import HealthKit

class BMRCalculator: ObservableObject {
    static let shared = BMRCalculator()
    
    @Published var bmr: Double = 0
    @Published var tdee: Double = 0 // Total Daily Energy Expenditure
    @Published var activityLevel: ActivityLevel = .moderate
    
    private init() {}
    
    // MARK: - Activity Levels
    enum ActivityLevel: String, CaseIterable {
        case sedentary = "sedentary"
        case lightlyActive = "lightlyActive"
        case moderate = "moderate"
        case veryActive = "veryActive"
        case extremelyActive = "extremelyActive"
        
        var multiplier: Double {
            switch self {
            case .sedentary: return 1.2
            case .lightlyActive: return 1.375
            case .moderate: return 1.55
            case .veryActive: return 1.725
            case .extremelyActive: return 1.9
            }
        }
        
        var displayName: String {
            switch self {
            case .sedentary: return "座り仕事中心"
            case .lightlyActive: return "軽い運動"
            case .moderate: return "適度な運動"
            case .veryActive: return "激しい運動"
            case .extremelyActive: return "非常に激しい運動"
            }
        }
    }
    
    // MARK: - BMR Calculation Methods
    
    /// Mifflin-St Jeor式でBMRを計算
    func calculateBMR(weight: Double, height: Double, age: Int, gender: Gender) -> Double {
        switch gender {
        case .male:
            return (10 * weight) + (6.25 * height) - (5 * Double(age)) + 5
        case .female:
            return (10 * weight) + (6.25 * height) - (5 * Double(age)) - 161
        }
    }
    
    /// TDEE（総消費カロリー）を計算
    func calculateTDEE(bmr: Double, activityLevel: ActivityLevel) -> Double {
        return bmr * activityLevel.multiplier
    }
    
    /// 筋肉増加に必要なカロリーを計算
    func calculateMuscleGainCalories(tdee: Double, bodyFatPercentage: Double) -> Double {
        // 体脂肪率が高い場合は減量しながら筋肉増加
        if bodyFatPercentage > 20 {
            return tdee - 200 // 軽いカロリー制限
        } else {
            return tdee + 300 // カロリーサープラス
        }
    }
    
    /// 脂肪燃焼に最適なカロリーを計算
    func calculateFatLossCalories(tdee: Double, bodyFatPercentage: Double) -> Double {
        if bodyFatPercentage > 25 {
            return tdee - 500 // 大幅なカロリー制限
        } else {
            return tdee - 300 // 適度なカロリー制限
        }
    }
    
    /// 筋肉維持に最適なカロリーを計算
    func calculateMuscleMaintenanceCalories(tdee: Double) -> Double {
        return tdee + 100 // 軽いサープラス
    }
}

// MARK: - Supporting Types
enum Gender: String, CaseIterable {
    case male = "male"
    case female = "female"
    
    var displayName: String {
        switch self {
        case .male: return "男性"
        case .female: return "女性"
        }
    }
} 