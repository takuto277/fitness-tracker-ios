import SwiftUI
import HealthKit
import Combine

// MARK: - Output
struct NutritionAnalysisOutput {
    var todayCalories: Double = 0
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
    var showingInputSheet: Bool = false
    var showingPhotoAnalysis: Bool = false
    var isLoading: Bool = false
}

// MARK: - ViewModel
@MainActor
class NutritionAnalysisViewModel: ObservableObject {
    @Published var output = NutritionAnalysisOutput()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        updateCalculations()
    }
    
    private func setupBindings() {
        // NutritionManagerのデータ変更を監視
        NutritionManager.shared.$todayCalories
            .assign(to: \.output.todayCalories, on: self)
            .store(in: &cancellables)
        
        NutritionManager.shared.$todayProtein
            .assign(to: \.output.todayProtein, on: self)
            .store(in: &cancellables)
        
        NutritionManager.shared.$todayCarbs
            .assign(to: \.output.todayCarbs, on: self)
            .store(in: &cancellables)
        
        NutritionManager.shared.$todayFat
            .assign(to: \.output.todayFat, on: self)
            .store(in: &cancellables)
        
        // データ変更時に計算を更新
        Publishers.CombineLatest4(
            NutritionManager.shared.$todayProtein,
            NutritionManager.shared.$todayCarbs,
            NutritionManager.shared.$todayFat,
            NutritionManager.shared.$todayCalories
        )
        .sink { [weak self] _, _, _, _ in
            self?.updateCalculations()
        }
        .store(in: &cancellables)
    }
    
    private func updateCalculations() {
        // 総カロリー計算
        output.totalCalories = output.todayProtein * 4 + output.todayCarbs * 4 + output.todayFat * 9
        
        // 栄養素バランス計算
        if output.totalCalories > 0 {
            output.proteinPercentage = (output.todayProtein * 4) / output.totalCalories
            output.carbsPercentage = (output.todayCarbs * 4) / output.totalCalories
            output.fatPercentage = (output.todayFat * 9) / output.totalCalories
        } else {
            output.proteinPercentage = 0
            output.carbsPercentage = 0
            output.fatPercentage = 0
        }
        
        // アドバイス更新
        updateAdvice()
    }
    
    private func updateAdvice() {
        // タンパク質アドバイス
        if output.todayProtein < 60 {
            output.proteinAdvice = "タンパク質が不足しています。鶏肉、魚、卵、豆類を積極的に摂取しましょう。"
        } else if output.todayProtein > 120 {
            output.proteinAdvice = "タンパク質の摂取量が多すぎます。適度な量に調整しましょう。"
        } else {
            output.proteinAdvice = "タンパク質の摂取量は適切です。この調子で維持しましょう。"
        }
        
        // 炭水化物アドバイス
        if output.todayCarbs < 100 {
            output.carbsAdvice = "炭水化物が不足しています。ご飯、パン、麺類を適度に摂取しましょう。"
        } else if output.todayCarbs > 300 {
            output.carbsAdvice = "炭水化物の摂取量が多すぎます。減量中は控えめにしましょう。"
        } else {
            output.carbsAdvice = "炭水化物の摂取量は適切です。"
        }
        
        // 脂質アドバイス
        if output.todayFat < 30 {
            output.fatAdvice = "脂質が不足しています。良質な油（オリーブオイル、ナッツ類）を摂取しましょう。"
        } else if output.todayFat > 80 {
            output.fatAdvice = "脂質の摂取量が多すぎます。揚げ物や脂っこい料理を控えましょう。"
        } else {
            output.fatAdvice = "脂質の摂取量は適切です。"
        }
    }
    
    // MARK: - Actions
    func refreshData() async {
        output.isLoading = true
        NutritionManager.shared.fetchTodayNutritionData()
        output.isLoading = false
    }
    
    func showInputSheet() {
        output.showingInputSheet = true
    }
    
    func hideInputSheet() {
        output.showingInputSheet = false
    }
    
    func showPhotoAnalysis() {
        output.showingPhotoAnalysis = true
    }
    
    func hidePhotoAnalysis() {
        output.showingPhotoAnalysis = false
    }
    
    func addNutritionData(calories: Double, protein: Double, carbs: Double, fat: Double) {
        NutritionManager.shared.addNutritionData(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat
        )
    }
} 