import Foundation
import HealthKit

// MARK: - Fitness Data Models
struct FitnessDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let caloriesIn: Double
    let caloriesOut: Double
    let bodyFatPercentage: Double
    let workoutIntensity: Double
    let muscleGainEfficiency: Double
    let fatLossEfficiency: Double
}

struct WorkoutIntensityData: Identifiable {
    let id = UUID()
    let date: Date
    let workoutType: String
    let duration: TimeInterval
    let caloriesBurned: Double
    let averageHeartRate: Double
    let intensity: Double // 0.0-1.0
}

struct NutritionData: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let water: Double
}

struct FitnessBodyCompositionData: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
    let bodyFatPercentage: Double
    let muscleMass: Double
    let bodyWaterPercentage: Double
}

// MARK: - Analysis Results
struct FitnessAnalysisResult {
    let optimalCalorieSurplus: Double
    let optimalWorkoutIntensity: Double
    let recommendedProteinIntake: Double
    let muscleGainPrediction: Double
    let fatLossPrediction: Double
    let efficiencyScore: Double
}

// MARK: - Fitness Analysis Calculator
class FitnessAnalysisCalculator: ObservableObject {
    @Published var fitnessData: [FitnessDataPoint] = []
    @Published var workoutData: [WorkoutIntensityData] = []
    @Published var nutritionData: [NutritionData] = []
    @Published var bodyCompositionData: [FitnessBodyCompositionData] = []
    @Published var analysisResult: FitnessAnalysisResult?
    
    private let healthKitManager = HealthKitManager()
    
    // MARK: - Data Fetching
    
    func fetchAnalysisData() {
        // すべてのデータを並行して取得
        let group = DispatchGroup()
        
        group.enter()
        fetchWorkoutData {
            group.leave()
        }
        
        group.enter()
        fetchNutritionData {
            group.leave()
        }
        
        group.enter()
        fetchBodyCompositionData {
            group.leave()
        }
        
        // すべてのデータ取得完了後に分析を実行
        group.notify(queue: .main) {
            self.calculateFitnessData()
        }
    }
    
    private func fetchWorkoutData(completion: @escaping () -> Void) {
        // 過去90日間のワークアウトデータを取得
        let startDate = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        
        healthKitManager.fetchRecentStrengthWorkouts { workouts in
            DispatchQueue.main.async {
                self.workoutData = workouts.map { workout in
                    let intensity = self.calculateWorkoutIntensity(workout: workout)
                    return WorkoutIntensityData(
                        date: workout.startDate,
                        workoutType: workout.workoutActivityType.displayName,
                        duration: TimeInterval(workout.duration),
                        caloriesBurned: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                        averageHeartRate: 0, // HealthKitから心拍数データを取得する必要があります
                        intensity: intensity
                    )
                }
                completion()
            }
        }
    }
    
    private func fetchNutritionData(completion: @escaping () -> Void) {
        // HealthKitから栄養データを取得
        let startDate = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        
        healthKitManager.fetchNutritionData(from: startDate, to: Date()) { nutritionData in
            DispatchQueue.main.async {
                self.nutritionData = nutritionData
                completion()
            }
        }
    }
    
    private func fetchBodyCompositionData(completion: @escaping () -> Void) {
        // HealthKitから体組成データを取得
        let startDate = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        
        healthKitManager.fetchBodyCompositionData(from: startDate, to: Date()) { bodyCompositionData in
            DispatchQueue.main.async {
                self.bodyCompositionData = bodyCompositionData
                completion()
            }
        }
    }
    
    // MARK: - Calculations
    
    private func calculateWorkoutIntensity(workout: HKWorkout) -> Double {
        let duration = TimeInterval(workout.duration)
        let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
        
        // durationが0の場合は強度0を返す
        guard duration > 0 else { return 0.0 }
        
        // 強度計算: カロリー/時間を基準に計算
        let caloriesPerHour = calories / (duration / 3600)
        let maxCaloriesPerHour = 800.0 // 最大強度の基準
        
        let intensity = min(caloriesPerHour / maxCaloriesPerHour, 1.0)
        
        // 無限大やNaNをチェック
        return intensity.isFinite ? intensity : 0.0
    }
    
    private func calculateFitnessData() {
        var dataPoints: [FitnessDataPoint] = []
        
        // 実際のデータがある日のみを処理
        let allDates = Set(
            nutritionData.map { Calendar.current.startOfDay(for: $0.date) } +
            workoutData.map { Calendar.current.startOfDay(for: $0.date) } +
            bodyCompositionData.map { Calendar.current.startOfDay(for: $0.date) }
        )
        
        let sortedDates = allDates.sorted()
        
        for date in sortedDates {
            let caloriesIn = getCaloriesIn(for: date)
            let caloriesOut = getCaloriesOut(for: date)
            let bodyFatPercentage = getBodyFatPercentage(for: date)
            let workoutIntensity = getWorkoutIntensity(for: date)
            
            // データが存在する場合のみデータポイントを作成
            if caloriesIn > 0 || caloriesOut > 0 || bodyFatPercentage > 0 || workoutIntensity > 0 {
                let muscleGainEfficiency = calculateMuscleGainEfficiency(
                    caloriesIn: caloriesIn,
                    caloriesOut: caloriesOut,
                    workoutIntensity: workoutIntensity
                )
                
                let fatLossEfficiency = calculateFatLossEfficiency(
                    caloriesIn: caloriesIn,
                    caloriesOut: caloriesOut,
                    workoutIntensity: workoutIntensity
                )
                
                let dataPoint = FitnessDataPoint(
                    date: date,
                    caloriesIn: caloriesIn,
                    caloriesOut: caloriesOut,
                    bodyFatPercentage: bodyFatPercentage,
                    workoutIntensity: workoutIntensity,
                    muscleGainEfficiency: muscleGainEfficiency,
                    fatLossEfficiency: fatLossEfficiency
                )
                
                dataPoints.append(dataPoint)
            }
        }
        
        // 日付順にソート（古い順）
        fitnessData = dataPoints.sorted { $0.date < $1.date }
        performAnalysis()
    }
    
    private func getCaloriesIn(for date: Date) -> Double {
        // 栄養データから該当日のカロリー摂取量を取得
        let dayData = nutritionData.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        return dayData.first?.calories ?? 0.0
    }
    
    private func getCaloriesOut(for date: Date) -> Double {
        // ワークアウトデータから該当日のカロリー消費量を取得
        let dayData = workoutData.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        return dayData.reduce(0) { $0 + $1.caloriesBurned }
    }
    
    private func getBodyFatPercentage(for date: Date) -> Double {
        // 体組成データから該当日の体脂肪率を取得
        let dayData = bodyCompositionData.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        return dayData.first?.bodyFatPercentage ?? 0.0
    }
    
    private func getWorkoutIntensity(for date: Date) -> Double {
        // ワークアウトデータから該当日の平均強度を取得
        let dayData = workoutData.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        if dayData.isEmpty { return 0.0 }
        return dayData.reduce(0) { $0 + $1.intensity } / Double(dayData.count)
    }
    
    // MARK: - Efficiency Calculations
    
    private func calculateMuscleGainEfficiency(caloriesIn: Double, caloriesOut: Double, workoutIntensity: Double) -> Double {
        let calorieSurplus = caloriesIn - caloriesOut
        let baseMetabolicRate = 1500.0 // 基礎代謝率（簡易計算）
        let maintenanceCalories = baseMetabolicRate * 1.2 // 活動レベルを考慮
        
        // 筋肉増加に最適なカロリーサープラス: 200-500kcal
        let optimalSurplus = 350.0
        let surplusEfficiency = 1.0 - abs(calorieSurplus - optimalSurplus) / optimalSurplus
        let surplusEfficiencyClamped = max(0.0, min(1.0, surplusEfficiency))
        
        // ワークアウト強度の効率（0.6-0.8が最適）
        let intensityEfficiency = 1.0 - abs(workoutIntensity - 0.7) / 0.7
        let intensityEfficiencyClamped = max(0.0, min(1.0, intensityEfficiency))
        
        // 総合効率（カロリーサープラス60%、強度40%の重み）
        let efficiency = surplusEfficiencyClamped * 0.6 + intensityEfficiencyClamped * 0.4
        
        // 無限大やNaNをチェック
        return efficiency.isFinite ? efficiency : 0.0
    }
    
    private func calculateFatLossEfficiency(caloriesIn: Double, caloriesOut: Double, workoutIntensity: Double) -> Double {
        let calorieDeficit = caloriesOut - caloriesIn
        let baseMetabolicRate = 1500.0
        let maintenanceCalories = baseMetabolicRate * 1.2
        
        // 脂肪減少に最適なカロリーデフィシット: 300-700kcal
        let optimalDeficit = 500.0
        let deficitEfficiency = 1.0 - abs(calorieDeficit - optimalDeficit) / optimalDeficit
        let deficitEfficiencyClamped = max(0.0, min(1.0, deficitEfficiency))
        
        // ワークアウト強度の効率（0.5-0.8が最適）
        let intensityEfficiency = 1.0 - abs(workoutIntensity - 0.65) / 0.65
        let intensityEfficiencyClamped = max(0.0, min(1.0, intensityEfficiency))
        
        // 総合効率（カロリーデフィシット70%、強度30%の重み）
        let efficiency = deficitEfficiencyClamped * 0.7 + intensityEfficiencyClamped * 0.3
        
        // 無限大やNaNをチェック
        return efficiency.isFinite ? efficiency : 0.0
    }
    
    // MARK: - Analysis
    
    private func performAnalysis() {
        guard !fitnessData.isEmpty else { return }
        
        // 最適なカロリーサープラスを計算
        let muscleGainData = fitnessData.sorted { $0.muscleGainEfficiency > $1.muscleGainEfficiency }
        let topMuscleGainData = Array(muscleGainData.prefix(5))
        let optimalCalorieSurplus = topMuscleGainData.isEmpty ? 0.0 : 
            topMuscleGainData.reduce(0) { $0 + ($1.caloriesIn - $1.caloriesOut) } / Double(topMuscleGainData.count)
        
        // 最適なワークアウト強度を計算
        let optimalWorkoutIntensity = topMuscleGainData.isEmpty ? 0.0 :
            topMuscleGainData.reduce(0) { $0 + $1.workoutIntensity } / Double(topMuscleGainData.count)
        
        // 推奨タンパク質摂取量（体重1kgあたり2.0g）
        let recommendedProteinIntake = 70.0 * 2.0 // 70kgの体重を想定
        
        // 筋肉増加予測
        let averageMuscleGainEfficiency = fitnessData.reduce(0) { $0 + $1.muscleGainEfficiency } / Double(fitnessData.count)
        let muscleGainPrediction = averageMuscleGainEfficiency * 0.5 // 月0.5kg増加を基準
        
        // 脂肪減少予測
        let averageFatLossEfficiency = fitnessData.reduce(0) { $0 + $1.fatLossEfficiency } / Double(fitnessData.count)
        let fatLossPrediction = averageFatLossEfficiency * 0.8 // 月0.8kg減少を基準
        
        // 総合効率スコア
        let efficiencyScore = (averageMuscleGainEfficiency + averageFatLossEfficiency) / 2.0
        
        analysisResult = FitnessAnalysisResult(
            optimalCalorieSurplus: optimalCalorieSurplus.isFinite ? optimalCalorieSurplus : 0.0,
            optimalWorkoutIntensity: optimalWorkoutIntensity.isFinite ? optimalWorkoutIntensity : 0.0,
            recommendedProteinIntake: recommendedProteinIntake.isFinite ? recommendedProteinIntake : 0.0,
            muscleGainPrediction: muscleGainPrediction.isFinite ? muscleGainPrediction : 0.0,
            fatLossPrediction: fatLossPrediction.isFinite ? fatLossPrediction : 0.0,
            efficiencyScore: efficiencyScore.isFinite ? efficiencyScore : 0.0
        )
    }
} 