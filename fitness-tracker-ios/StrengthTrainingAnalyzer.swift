import Foundation
import HealthKit
import Combine

class StrengthTrainingAnalyzer: ObservableObject {
    static let shared = StrengthTrainingAnalyzer()
    
    @Published var weeklyWorkoutFrequency: Int = 0
    @Published var averageWorkoutDuration: TimeInterval = 0
    @Published var muscleGainPotential: Double = 0
    @Published var recommendedWorkoutFrequency: Int = 0
    @Published var muscleGainPrediction: MuscleGainPrediction = .moderate
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Muscle Gain Prediction
    enum MuscleGainPrediction: String, CaseIterable {
        case low = "low"
        case moderate = "moderate"
        case high = "high"
        case excellent = "excellent"
        
        var displayName: String {
            switch self {
            case .low: return "低い"
            case .moderate: return "中程度"
            case .high: return "高い"
            case .excellent: return "非常に高い"
            }
        }
        
        var description: String {
            switch self {
            case .low: return "筋トレ頻度を増やしましょう"
            case .moderate: return "現在のペースを維持しましょう"
            case .high: return "素晴らしい進捗です"
            case .excellent: return "理想的な筋トレ習慣です"
            }
        }
        
        var monthlyGain: Double {
            switch self {
            case .low: return 0.2
            case .moderate: return 0.5
            case .high: return 0.8
            case .excellent: return 1.2
            }
        }
    }
    
    // MARK: - Analysis Methods
    
    /// 週間の筋トレ頻度を分析
    func analyzeWeeklyWorkoutFrequency(workouts: [HKWorkout]) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        
        let weeklyWorkouts = workouts.filter { workout in
            workout.workoutActivityType == .traditionalStrengthTraining &&
            workout.startDate >= weekAgo
        }
        
        return weeklyWorkouts.count
    }
    
    /// 平均ワークアウト時間を計算
    func calculateAverageWorkoutDuration(workouts: [HKWorkout]) -> TimeInterval {
        let strengthWorkouts = workouts.filter { $0.workoutActivityType == .traditionalStrengthTraining }
        
        guard !strengthWorkouts.isEmpty else { return 0 }
        
        let totalDuration = strengthWorkouts.reduce(0) { $0 + TimeInterval($1.duration) }
        return totalDuration / Double(strengthWorkouts.count)
    }
    
    /// 筋肉増加ポテンシャルを計算
    func calculateMuscleGainPotential(
        workoutFrequency: Int,
        workoutDuration: TimeInterval,
        currentMuscleMass: Double,
        bodyFatPercentage: Double,
        nutritionQuality: Double
    ) -> Double {
        // 筋トレ頻度スコア (0-1)
        let frequencyScore = min(Double(workoutFrequency) / 4.0, 1.0)
        
        // ワークアウト時間スコア (0-1)
        let durationScore = min(workoutDuration / 3600.0, 1.0) // 1時間を基準
        
        // 体脂肪率スコア (低いほど良い)
        let bodyFatScore = max(0, 1.0 - (bodyFatPercentage / 30.0))
        
        // 栄養品質スコア (0-1)
        let nutritionScore = nutritionQuality
        
        // 総合スコア
        let totalScore = (frequencyScore * 0.3) + 
                        (durationScore * 0.2) + 
                        (bodyFatScore * 0.2) + 
                        (nutritionScore * 0.3)
        
        return totalScore
    }
    
    /// 推奨筋トレ頻度を計算
    func calculateRecommendedWorkoutFrequency(
        currentFrequency: Int,
        muscleGainPotential: Double,
        bodyFatPercentage: Double
    ) -> Int {
        if muscleGainPotential < 0.3 {
            return max(3, currentFrequency + 1)
        } else if muscleGainPotential > 0.7 {
            return currentFrequency
        } else {
            return max(2, currentFrequency)
        }
    }
    
    /// 筋肉増加予測を計算
    func predictMuscleGain(
        muscleGainPotential: Double,
        currentMuscleMass: Double,
        bodyFatPercentage: Double
    ) -> MuscleGainPrediction {
        let score = muscleGainPotential
        
        if score >= 0.8 {
            return .excellent
        } else if score >= 0.6 {
            return .high
        } else if score >= 0.4 {
            return .moderate
        } else {
            return .low
        }
    }
    
    /// 理想体型までの予測期間を計算
    func calculateTimeToGoal(
        currentMuscleMass: Double,
        targetMuscleMass: Double,
        muscleGainPrediction: MuscleGainPrediction
    ) -> Int {
        let muscleGainNeeded = targetMuscleMass - currentMuscleMass
        let monthlyGain = muscleGainPrediction.monthlyGain
        
        guard monthlyGain > 0 else { return 0 }
        
        return Int(ceil(muscleGainNeeded / monthlyGain))
    }
    
    /// 筋トレ効果の最適化アドバイスを生成
    func generateOptimizationAdvice(
        workoutFrequency: Int,
        workoutDuration: TimeInterval,
        muscleGainPotential: Double,
        bodyFatPercentage: Double
    ) -> [String] {
        var advice: [String] = []
        
        // 頻度に関するアドバイス
        if workoutFrequency < 3 {
            advice.append("週3回以上の筋トレを心がけましょう")
        } else if workoutFrequency > 5 {
            advice.append("回復時間を確保するため、週5回以下に調整しましょう")
        }
        
        // 時間に関するアドバイス
        if workoutDuration < 1800 { // 30分未満
            advice.append("筋トレ時間を30分以上に延長しましょう")
        } else if workoutDuration > 5400 { // 90分以上
            advice.append("長時間の筋トレは疲労の原因になります")
        }
        
        // 体脂肪率に関するアドバイス
        if bodyFatPercentage > 25 {
            advice.append("体脂肪率を下げることで筋肉増加効果が向上します")
        }
        
        // 総合的なアドバイス
        if muscleGainPotential < 0.4 {
            advice.append("筋トレの強度と頻度を上げましょう")
        } else if muscleGainPotential > 0.7 {
            advice.append("現在のペースを維持しましょう")
        }
        
        return advice
    }
} 