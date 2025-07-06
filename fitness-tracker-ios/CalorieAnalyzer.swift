import Foundation
import HealthKit
import Combine

class CalorieAnalyzer: ObservableObject {
    static let shared = CalorieAnalyzer()
    
    @Published var dailyCalorieBalance: Double = 0
    @Published var weeklyCalorieBalance: Double = 0
    @Published var muscleGainEfficiency: Double = 0
    @Published var optimalCalorieRange: CalorieRange = .maintenance
    @Published var calorieAdvice: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Calorie Range Types
    enum CalorieRange: String, CaseIterable {
        case deficit = "deficit"
        case maintenance = "maintenance"
        case surplus = "surplus"
        case optimalMuscleGain = "optimalMuscleGain"
        
        var displayName: String {
            switch self {
            case .deficit: return "カロリー不足"
            case .maintenance: return "維持"
            case .surplus: return "カロリー過多"
            case .optimalMuscleGain: return "筋肉増加最適"
            }
        }
        
        var description: String {
            switch self {
            case .deficit: return "減量に適している"
            case .maintenance: return "体重維持に適している"
            case .surplus: return "筋肉増加に適している"
            case .optimalMuscleGain: return "効率的な筋肉増加"
            }
        }
    }
    
    // MARK: - Analysis Methods
    
    /// 日次カロリー収支を計算
    func calculateDailyCalorieBalance(
        consumed: Double,
        burned: Double,
        bmr: Double
    ) -> Double {
        let totalBurned = burned + bmr
        return consumed - totalBurned
    }
    
    /// 週間カロリー収支を計算
    func calculateWeeklyCalorieBalance(dailyBalances: [Double]) -> Double {
        return dailyBalances.reduce(0, +)
    }
    
    /// 筋肉増加効率を計算
    func calculateMuscleGainEfficiency(
        calorieBalance: Double,
        proteinIntake: Double,
        bodyFatPercentage: Double,
        workoutFrequency: Int
    ) -> Double {
        // カロリー収支スコア (0-1)
        let calorieScore: Double
        if bodyFatPercentage > 20 {
            // 体脂肪率が高い場合は軽いカロリー制限が効率的
            calorieScore = max(0, 1.0 - abs(calorieBalance + 200) / 500.0)
        } else {
            // 体脂肪率が低い場合はカロリーサープラスが効率的
            calorieScore = max(0, 1.0 - abs(calorieBalance - 300) / 500.0)
        }
        
        // タンパク質摂取スコア (0-1)
        let proteinScore = min(proteinIntake / 120.0, 1.0) // 120gを基準
        
        // 筋トレ頻度スコア (0-1)
        let workoutScore = min(Double(workoutFrequency) / 4.0, 1.0)
        
        // 体脂肪率スコア (低いほど良い)
        let bodyFatScore = max(0, 1.0 - (bodyFatPercentage / 30.0))
        
        // 総合効率スコア
        let totalEfficiency = (calorieScore * 0.3) + 
                             (proteinScore * 0.3) + 
                             (workoutScore * 0.2) + 
                             (bodyFatScore * 0.2)
        
        return totalEfficiency
    }
    
    /// 最適カロリー範囲を判定
    func determineOptimalCalorieRange(
        calorieBalance: Double,
        bodyFatPercentage: Double,
        muscleGainEfficiency: Double
    ) -> CalorieRange {
        if bodyFatPercentage > 25 {
            // 体脂肪率が高い場合は減量優先
            if calorieBalance < -300 {
                return .deficit
            } else if calorieBalance > 100 {
                return .surplus
            } else {
                return .maintenance
            }
        } else if muscleGainEfficiency > 0.7 {
            // 筋肉増加効率が高い場合は最適範囲
            if calorieBalance >= 200 && calorieBalance <= 500 {
                return .optimalMuscleGain
            } else if calorieBalance > 500 {
                return .surplus
            } else {
                return .maintenance
            }
        } else {
            // 通常の判定
            if calorieBalance < -200 {
                return .deficit
            } else if calorieBalance > 300 {
                return .surplus
            } else {
                return .maintenance
            }
        }
    }
    
    /// カロリーアドバイスを生成
    func generateCalorieAdvice(
        calorieBalance: Double,
        optimalRange: CalorieRange,
        bodyFatPercentage: Double,
        muscleGainEfficiency: Double
    ) -> String {
        switch optimalRange {
        case .deficit:
            if bodyFatPercentage > 25 {
                return "体脂肪率が高いため、カロリー制限を継続しましょう。週に0.5kg程度の減量が理想的です。"
            } else {
                return "軽いカロリー制限で体脂肪を減らしながら筋肉を維持しましょう。"
            }
            
        case .maintenance:
            if muscleGainEfficiency > 0.6 {
                return "現在のカロリー収支は良好です。筋トレの強度を上げることで筋肉増加を促進できます。"
            } else {
                return "カロリー収支は適切ですが、タンパク質摂取量と筋トレ頻度を改善しましょう。"
            }
            
        case .surplus:
            if bodyFatPercentage < 15 {
                return "カロリーサープラスにより筋肉増加が期待できます。体脂肪の増加に注意しましょう。"
            } else {
                return "カロリーが多すぎます。適度な制限で筋肉増加と脂肪燃焼のバランスを取りましょう。"
            }
            
        case .optimalMuscleGain:
            return "理想的なカロリー収支です！効率的な筋肉増加が期待できます。このペースを維持しましょう。"
        }
    }
    
    /// 筋肉増加に最適なカロリー範囲を計算
    func calculateOptimalCalorieRange(
        tdee: Double,
        bodyFatPercentage: Double,
        workoutFrequency: Int
    ) -> (min: Double, max: Double) {
        let baseCalories = tdee
        
        if bodyFatPercentage > 20 {
            // 体脂肪率が高い場合は軽い制限
            return (baseCalories - 300, baseCalories - 100)
        } else if workoutFrequency >= 4 {
            // 筋トレ頻度が高い場合はサープラス
            return (baseCalories + 200, baseCalories + 400)
        } else {
            // 通常の範囲
            return (baseCalories - 100, baseCalories + 200)
        }
    }
    
    /// 週間のカロリー収支トレンドを分析
    func analyzeWeeklyCalorieTrend(dailyBalances: [Double]) -> String {
        guard dailyBalances.count >= 7 else { return "データ不足" }
        
        let averageBalance = dailyBalances.reduce(0, +) / Double(dailyBalances.count)
        let positiveDays = dailyBalances.filter { $0 > 0 }.count
        let negativeDays = dailyBalances.filter { $0 < 0 }.count
        
        if averageBalance > 300 {
            return "週間平均でカロリーサープラス。筋肉増加に適しているが、体脂肪の増加に注意。"
        } else if averageBalance < -300 {
            return "週間平均でカロリー不足。減量効果はあるが、筋肉維持に注意。"
        } else if positiveDays > negativeDays {
            return "週間を通じて適度なカロリーサープラス。バランスの良い状態。"
        } else {
            return "週間を通じてカロリー不足。栄養摂取を改善しましょう。"
        }
    }
} 