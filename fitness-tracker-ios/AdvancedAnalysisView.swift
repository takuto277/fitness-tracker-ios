import SwiftUI
import HealthKit
import Combine

struct AdvancedAnalysisView: View {
    @StateObject private var viewModel = AdvancedAnalysisViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 筋肉増加効率分析
                    muscleGainEfficiencySection
                    
                    // カロリー収支分析
                    calorieBalanceSection
                    
                    // 筋トレ頻度分析
                    workoutFrequencySection
                    
                    // 理想体型予測
                    bodyCompositionPredictionSection
                    
                    // 最適化アドバイス
                    optimizationAdviceSection
                }
                .padding()
            }
            .navigationTitle("詳細分析")
            .onAppear {
                Task {
                    await viewModel.loadData()
                }
            }
        }
    }
    
    private var muscleGainEfficiencySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("筋肉増加効率分析")
                .font(.title2)
                .fontWeight(.bold)
            
            MuscleGainEfficiencyChartView(
                efficiency: viewModel.output.muscleGainEfficiency,
                calorieBalance: viewModel.output.dailyCalorieBalance,
                proteinIntake: viewModel.output.todayProtein
            )
            
            Text(viewModel.output.muscleGainAdvice)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
        }
    }
    
    private var calorieBalanceSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("カロリー収支分析")
                .font(.title2)
                .fontWeight(.bold)
            
            CalorieBalanceTrendChartView(dailyBalances: viewModel.output.weeklyCalorieBalances)
            
            HStack(spacing: 20) {
                VStack {
                    Text("最適範囲")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.output.optimalCalorieRange.displayName)
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
                VStack {
                    Text("現在の収支")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(viewModel.output.dailyCalorieBalance))kcal")
                        .font(.headline)
                        .foregroundColor(calorieBalanceColor)
                }
            }
            
            Text(viewModel.output.calorieAdvice)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
        }
    }
    
    private var workoutFrequencySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("筋トレ頻度分析")
                .font(.title2)
                .fontWeight(.bold)
            
            WorkoutFrequencyChartView(
                weeklyFrequency: viewModel.output.weeklyWorkoutFrequency,
                recommendedFrequency: viewModel.output.recommendedWorkoutFrequency,
                averageDuration: viewModel.output.averageWorkoutDuration
            )
            
            Text(viewModel.output.workoutAdvice)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
        }
    }
    
    private var bodyCompositionPredictionSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("理想体型予測")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 10) {
                HStack {
                    Text("現在の筋肉量")
                    Spacer()
                    Text("\(String(format: "%.1f", viewModel.output.currentMuscleMass))kg")
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("目標筋肉量")
                    Spacer()
                    Text("\(String(format: "%.1f", viewModel.output.targetMuscleMass))kg")
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("予測増加量/月")
                    Spacer()
                    Text("\(String(format: "%.1f", viewModel.output.predictedMonthlyGain))kg")
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("目標達成まで")
                    Spacer()
                    Text("\(viewModel.output.timeToGoal)ヶ月")
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    private var optimizationAdviceSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("最適化アドバイス")
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(viewModel.output.optimizationAdvice, id: \.self) { advice in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    
                    Text(advice)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.vertical, 5)
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var calorieBalanceColor: Color {
        let balance = viewModel.output.dailyCalorieBalance
        if balance >= 200 && balance <= 500 { return .green }
        else if balance > 500 { return .orange }
        else if balance < -200 { return .red }
        else { return .blue }
    }
}

// MARK: - ViewModel
@MainActor
class AdvancedAnalysisViewModel: ObservableObject {
    @Published var output = AdvancedAnalysisOutput()
    
    private let healthKitManager: HealthKitManager
    private let bmrCalculator = BMRCalculator.shared
    private let strengthAnalyzer = StrengthTrainingAnalyzer.shared
    private let calorieAnalyzer = CalorieAnalyzer.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.healthKitManager = HealthKitManager()
        setupBindings()
    }
    
    private func setupBindings() {
        // NutritionManagerのデータ変更を監視
        NutritionManager.shared.$todayProtein
            .assign(to: \.output.todayProtein, on: self)
            .store(in: &cancellables)
    }
    
    func loadData() async {
        await fetchWorkoutData()
        await calculateBMR()
        await analyzeCalorieBalance()
        await analyzeMuscleGainEfficiency()
        await generatePredictions()
        await generateAdvice()
    }
    
    private func fetchWorkoutData() async {
        // 過去7日間のワークアウトデータを取得
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        let workouts = await healthKitManager.fetchWorkouts(from: startDate, to: endDate)
        
        output.weeklyWorkoutFrequency = strengthAnalyzer.analyzeWeeklyWorkoutFrequency(workouts: workouts)
        output.averageWorkoutDuration = strengthAnalyzer.calculateAverageWorkoutDuration(workouts: workouts)
    }
    
    private func calculateBMR() async {
        // ユーザーの基本情報を取得（実際のアプリでは設定から取得）
        let weight = 70.0 // kg
        let height = 170.0 // cm
        let age = 30
        let gender = Gender.male
        
        let bmr = bmrCalculator.calculateBMR(weight: weight, height: height, age: age, gender: gender)
        let tdee = bmrCalculator.calculateTDEE(bmr: bmr, activityLevel: .moderate)
        
        output.bmr = bmr
        output.tdee = tdee
    }
    
    private func analyzeCalorieBalance() async {
        let consumed = NutritionManager.shared.todayCalories
        let burned = 300.0 // 実際のアプリではHealthKitから取得
        
        output.dailyCalorieBalance = calorieAnalyzer.calculateDailyCalorieBalance(
            consumed: consumed,
            burned: burned,
            bmr: output.bmr
        )
        
        // 週間のカロリー収支を計算（ダミーデータ）
        output.weeklyCalorieBalances = [-150, 200, -50, 300, 100, -100, 250]
        output.weeklyCalorieBalance = calorieAnalyzer.calculateWeeklyCalorieBalance(
            dailyBalances: output.weeklyCalorieBalances
        )
        
        output.optimalCalorieRange = calorieAnalyzer.determineOptimalCalorieRange(
            calorieBalance: output.dailyCalorieBalance,
            bodyFatPercentage: 18.0, // 実際のアプリでは体組成から取得
            muscleGainEfficiency: output.muscleGainEfficiency
        )
    }
    
    private func analyzeMuscleGainEfficiency() async {
        output.muscleGainEfficiency = calorieAnalyzer.calculateMuscleGainEfficiency(
            calorieBalance: output.dailyCalorieBalance,
            proteinIntake: output.todayProtein,
            bodyFatPercentage: 18.0,
            workoutFrequency: output.weeklyWorkoutFrequency
        )
        
        output.recommendedWorkoutFrequency = strengthAnalyzer.calculateRecommendedWorkoutFrequency(
            currentFrequency: output.weeklyWorkoutFrequency,
            muscleGainPotential: output.muscleGainEfficiency,
            bodyFatPercentage: 18.0
        )
    }
    
    private func generatePredictions() async {
        output.currentMuscleMass = 45.0 // 実際のアプリでは体組成から取得
        output.targetMuscleMass = 50.0 // ユーザーの目標
        
        let prediction = strengthAnalyzer.predictMuscleGain(
            muscleGainPotential: output.muscleGainEfficiency,
            currentMuscleMass: output.currentMuscleMass,
            bodyFatPercentage: 18.0
        )
        
        output.predictedMonthlyGain = prediction.monthlyGain
        output.timeToGoal = strengthAnalyzer.calculateTimeToGoal(
            currentMuscleMass: output.currentMuscleMass,
            targetMuscleMass: output.targetMuscleMass,
            muscleGainPrediction: prediction
        )
    }
    
    private func generateAdvice() async {
        output.calorieAdvice = calorieAnalyzer.generateCalorieAdvice(
            calorieBalance: output.dailyCalorieBalance,
            optimalRange: output.optimalCalorieRange,
            bodyFatPercentage: 18.0,
            muscleGainEfficiency: output.muscleGainEfficiency
        )
        
        output.workoutAdvice = strengthAnalyzer.generateOptimizationAdvice(
            workoutFrequency: output.weeklyWorkoutFrequency,
            workoutDuration: output.averageWorkoutDuration,
            muscleGainPotential: output.muscleGainEfficiency,
            bodyFatPercentage: 18.0
        ).joined(separator: "\n")
        
        output.muscleGainAdvice = "現在の筋肉増加効率は\(Int(output.muscleGainEfficiency * 100))%です。"
        output.optimizationAdvice = [
            "タンパク質摂取量を120g以上に増やしましょう",
            "週3回以上の筋トレを継続しましょう",
            "カロリー収支を200-500kcalのサープラスに調整しましょう",
            "十分な睡眠と回復時間を確保しましょう"
        ]
    }
}

// MARK: - Output
struct AdvancedAnalysisOutput {
    var bmr: Double = 0
    var tdee: Double = 0
    var dailyCalorieBalance: Double = 0
    var weeklyCalorieBalance: Double = 0
    var weeklyCalorieBalances: [Double] = []
    var muscleGainEfficiency: Double = 0
    var optimalCalorieRange: CalorieAnalyzer.CalorieRange = .maintenance
    var weeklyWorkoutFrequency: Int = 0
    var recommendedWorkoutFrequency: Int = 0
    var averageWorkoutDuration: TimeInterval = 0
    var currentMuscleMass: Double = 0
    var targetMuscleMass: Double = 0
    var predictedMonthlyGain: Double = 0
    var timeToGoal: Int = 0
    var todayProtein: Double = 0
    var calorieAdvice: String = ""
    var workoutAdvice: String = ""
    var muscleGainAdvice: String = ""
    var optimizationAdvice: [String] = []
} 