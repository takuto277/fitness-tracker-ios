import SwiftUI
import HealthKit
import Combine

// MARK: - Output
struct ProgressAnalysisOutput {
    var weightProgress: Double = 0
    var muscleProgress: Double = 0
    var fitnessProgress: Double = 0
    var nutritionProgress: Double = 0
    var overallProgress: Double = 0
    var selectedPeriod: AnalysisPeriod = .week
    var progressData: [ProgressData] = []
    var averageCalorieBalance: Double = 0
    var weightAdvice: String = ""
    var muscleAdvice: String = ""
    var fitnessAdvice: String = ""
    var nutritionAdvice: String = ""
    var isLoading: Bool = false
    
    // 栄養関連のプロパティ
    var todayProtein: Double = 0
    var todayCarbs: Double = 0
    var todayFat: Double = 0
    var totalCalories: Double = 0
    var proteinPercentage: Double = 0
    var carbsPercentage: Double = 0
    var fatPercentage: Double = 0
    var proteinAdvice: String = ""
    var carbsAdvice: String = ""
    var fatAdvice: String = ""
}

// MARK: - ViewModel
@MainActor
class ProgressAnalysisViewModel: ObservableObject {
    @Published var output = ProgressAnalysisOutput()
    
    private let progressManager: ProgressManager
    private let healthKitManager: HealthKitManager
    private let bodyCompositionManager: BodyCompositionManager
    private var cancellables = Set<AnyCancellable>()
    
    init(
        progressManager: ProgressManager,
        healthKitManager: HealthKitManager,
        bodyCompositionManager: BodyCompositionManager
    ) {
        self.progressManager = progressManager
        self.healthKitManager = healthKitManager
        self.bodyCompositionManager = bodyCompositionManager
        setupBindings()
    }
    
    private func setupBindings() {
        // ProgressManagerのデータ変更を監視
        progressManager.$weightProgress
            .assign(to: \.output.weightProgress, on: self)
            .store(in: &cancellables)
        
        progressManager.$muscleProgress
            .assign(to: \.output.muscleProgress, on: self)
            .store(in: &cancellables)
        
        progressManager.$fitnessProgress
            .assign(to: \.output.fitnessProgress, on: self)
            .store(in: &cancellables)
        
        progressManager.$nutritionProgress
            .assign(to: \.output.nutritionProgress, on: self)
            .store(in: &cancellables)
        
        progressManager.$overallProgress
            .assign(to: \.output.overallProgress, on: self)
            .store(in: &cancellables)
        
        // NutritionManagerのデータ変更を監視
        NutritionManager.shared.$todayProtein
            .assign(to: \.output.todayProtein, on: self)
            .store(in: &cancellables)
        
        NutritionManager.shared.$todayCarbs
            .assign(to: \.output.todayCarbs, on: self)
            .store(in: &cancellables)
        
        NutritionManager.shared.$todayFat
            .assign(to: \.output.todayFat, on: self)
            .store(in: &cancellables)
        
        // 栄養データ変更時に計算を更新
        Publishers.CombineLatest3(
            NutritionManager.shared.$todayProtein,
            NutritionManager.shared.$todayCarbs,
            NutritionManager.shared.$todayFat
        )
        .sink { [weak self] _, _, _ in
            self?.updateNutritionCalculations()
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Actions
    func loadData() async {
        output.isLoading = true
        
        await progressManager.calculateProgress()
        await loadProgressData()
        updateAdvice()
        updateNutritionCalculations()
        
        output.isLoading = false
    }
    
    private func loadProgressData() async {
        // 期間に応じてデータを取得
        let endDate = Date()
        let startDate: Date
        
        switch output.selectedPeriod {
        case .week:
            startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .month:
            startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        case .quarter:
            startDate = Calendar.current.date(byAdding: .month, value: -3, to: endDate) ?? endDate
        }
        
        // 実際のアプリでは、期間に応じたデータを取得
        // ここではダミーデータを生成
        output.progressData = generateDummyProgressData(startDate: startDate, endDate: endDate)
        
        // 平均カロリーバランスを計算
        if !output.progressData.isEmpty {
            output.averageCalorieBalance = output.progressData.map { $0.calorieBalance }.reduce(0, +) / Double(output.progressData.count)
        }
    }
    
    private func generateDummyProgressData(startDate: Date, endDate: Date) -> [ProgressData] {
        var data: [ProgressData] = []
        let calendar = Calendar.current
        var currentDate = startDate
        
        while currentDate <= endDate {
            let weight = 70.0 + Double.random(in: -2...2)
            let muscleMass = 45.0 + Double.random(in: -1...1)
            let workoutDuration = Double.random(in: 0...120)
            let caloriesBurned = Double.random(in: 0...800)
            let caloriesConsumed = Double.random(in: 1500...2500)
            
            data.append(ProgressData(
                date: currentDate,
                weight: weight,
                muscleMass: muscleMass,
                workoutDuration: workoutDuration,
                caloriesBurned: caloriesBurned,
                caloriesConsumed: caloriesConsumed
            ))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return data
    }
    
    private func updateAdvice() {
        // 体重アドバイス
        if output.weightProgress < 0.3 {
            output.weightAdvice = "体重の目標達成に向けて、より積極的な取り組みが必要です。"
        } else if output.weightProgress < 0.7 {
            output.weightAdvice = "順調に進んでいます。この調子で継続しましょう。"
        } else {
            output.weightAdvice = "素晴らしい進捗です！目標達成まであと少しです。"
        }
        
        // 筋肉量アドバイス
        if output.muscleProgress < 0.3 {
            output.muscleAdvice = "筋肉量の増加が遅れています。筋トレの頻度と強度を見直しましょう。"
        } else if output.muscleProgress < 0.7 {
            output.muscleAdvice = "筋肉量は順調に増加しています。継続が大切です。"
        } else {
            output.muscleAdvice = "筋肉量の増加が順調です！理想的な体型に近づいています。"
        }
        
        // フィットネスアドバイス
        if output.fitnessProgress < 0.3 {
            output.fitnessAdvice = "運動習慣の改善が必要です。週3回以上の運動を心がけましょう。"
        } else if output.fitnessProgress < 0.7 {
            output.fitnessAdvice = "運動習慣が身についています。さらにレベルアップを目指しましょう。"
        } else {
            output.fitnessAdvice = "素晴らしい運動習慣です！健康な体を維持できています。"
        }
        
        // 栄養アドバイス
        if output.nutritionProgress < 0.3 {
            output.nutritionAdvice = "栄養管理の改善が必要です。バランスの良い食事を心がけましょう。"
        } else if output.nutritionProgress < 0.7 {
            output.nutritionAdvice = "栄養管理が順調です。さらに細かい調整を行いましょう。"
        } else {
            output.nutritionAdvice = "完璧な栄養管理です！理想的な食事習慣が身についています。"
        }
    }
    
    func selectPeriod(_ period: AnalysisPeriod) {
        output.selectedPeriod = period
        Task {
            await loadData()
        }
    }
    
    // MARK: - Nutrition Calculations
    private func updateNutritionCalculations() {
        // 総カロリー計算
        output.totalCalories = NutritionManager.shared.todayProtein * 4 + NutritionManager.shared.todayCarbs * 4 + NutritionManager.shared.todayFat * 9
        
        // 栄養素バランス計算
        if output.totalCalories > 0 {
            output.proteinPercentage = (NutritionManager.shared.todayProtein * 4) / output.totalCalories
            output.carbsPercentage = (NutritionManager.shared.todayCarbs * 4) / output.totalCalories
            output.fatPercentage = (NutritionManager.shared.todayFat * 9) / output.totalCalories
        } else {
            output.proteinPercentage = 0
            output.carbsPercentage = 0
            output.fatPercentage = 0
        }
        
        // 栄養アドバイス更新
        updateNutritionAdvice()
    }
    
    private func updateNutritionAdvice() {
        // タンパク質アドバイス
        if NutritionManager.shared.todayProtein < 60 {
            output.proteinAdvice = "タンパク質が不足しています。鶏肉、魚、卵、豆類を積極的に摂取しましょう。"
        } else if NutritionManager.shared.todayProtein > 120 {
            output.proteinAdvice = "タンパク質の摂取量が多すぎます。適度な量に調整しましょう。"
        } else {
            output.proteinAdvice = "タンパク質の摂取量は適切です。この調子で維持しましょう。"
        }
        
        // 炭水化物アドバイス
        if NutritionManager.shared.todayCarbs < 100 {
            output.carbsAdvice = "炭水化物が不足しています。ご飯、パン、麺類を適度に摂取しましょう。"
        } else if NutritionManager.shared.todayCarbs > 300 {
            output.carbsAdvice = "炭水化物の摂取量が多すぎます。減量中は控えめにしましょう。"
        } else {
            output.carbsAdvice = "炭水化物の摂取量は適切です。"
        }
        
        // 脂質アドバイス
        if NutritionManager.shared.todayFat < 30 {
            output.fatAdvice = "脂質が不足しています。良質な油（オリーブオイル、ナッツ類）を摂取しましょう。"
        } else if NutritionManager.shared.todayFat > 80 {
            output.fatAdvice = "脂質の摂取量が多すぎます。揚げ物や脂っこい料理を控えましょう。"
        } else {
            output.fatAdvice = "脂質の摂取量は適切です。"
        }
    }
}

// MARK: - Supporting Types
enum AnalysisPeriod: CaseIterable {
    case week, month, quarter
    
    var displayName: String {
        switch self {
        case .week:
            return "週間"
        case .month:
            return "月間"
        case .quarter:
            return "3ヶ月"
        }
    }
} 