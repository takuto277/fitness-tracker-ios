import SwiftUI
import HealthKit

struct ProgressAnalysisView: View {
    @StateObject private var viewModel: ProgressAnalysisViewModel
    
    init(
        progressManager: ProgressManager,
        healthKitManager: HealthKitManager,
        bodyCompositionManager: BodyCompositionManager
    ) {
        self._viewModel = StateObject(wrappedValue: ProgressAnalysisViewModel(
            progressManager: progressManager,
            healthKitManager: healthKitManager,
            bodyCompositionManager: bodyCompositionManager
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 全体進捗サマリー
                    overallProgressSection
                    
                    // 期間選択
                    periodSelector
                    
                    // 詳細分析
                    detailedAnalysisSection
                    
                    // アドバイス
                    adviceSection
                }
                .padding()
            }
            .navigationTitle("進捗分析")
            .onAppear {
                Task {
                    await viewModel.loadData()
                }
            }
        }
    }
    
    private var overallProgressSection: some View {
        VStack(spacing: 15) {
            Text("全体進捗")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                ProgressCircle(
                    title: "体重",
                    progress: viewModel.output.weightProgress,
                    color: .purple
                )
                
                ProgressCircle(
                    title: "筋肉量",
                    progress: viewModel.output.muscleProgress,
                    color: .green
                )
                
                ProgressCircle(
                    title: "フィットネス",
                    progress: viewModel.output.fitnessProgress,
                    color: .blue
                )
                
                ProgressCircle(
                    title: "栄養",
                    progress: viewModel.output.nutritionProgress,
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(AnalysisPeriod.allCases, id: \.self) { period in
                Button(action: {
                    viewModel.selectPeriod(period)
                }) {
                    Text(period.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            viewModel.output.selectedPeriod == period ? Color.blue : Color.clear
                        )
                        .foregroundColor(
                            viewModel.output.selectedPeriod == period ? .white : .primary
                        )
                }
            }
        }
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
    
    private var detailedAnalysisSection: some View {
        VStack(spacing: 15) {
            Text("詳細分析")
                .font(.headline)
            
            // 体重・筋肉量の推移
            weightMuscleSection
            
            // 運動・栄養の推移
            fitnessNutritionSection
            
            // カロリーバランス
            calorieBalanceSection
        }
    }
    
    private var weightMuscleSection: some View {
        VStack(spacing: 15) {
            Text("体重・筋肉量の推移")
                .font(.subheadline)
                .fontWeight(.bold)
            
            // 体重グラフ
            WeightChartView(progressData: viewModel.output.progressData)
            
            // 筋肉量グラフ
            MuscleMassChartView(progressData: viewModel.output.progressData)
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var fitnessNutritionSection: some View {
        VStack(spacing: 15) {
            Text("運動・栄養の推移")
                .font(.subheadline)
                .fontWeight(.bold)
            
            // カロリーバランスグラフ
            CalorieBalanceChartView(progressData: viewModel.output.progressData)
            
            // 栄養バランス円グラフ
            NutritionPieChartView(
                proteinPercentage: viewModel.output.proteinPercentage,
                carbsPercentage: viewModel.output.carbsPercentage,
                fatPercentage: viewModel.output.fatPercentage
            )
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var calorieBalanceSection: some View {
        VStack(spacing: 10) {
            Text("カロリーバランス")
                .font(.subheadline)
                .fontWeight(.bold)
            
            let averageBalance = viewModel.output.averageCalorieBalance
            
            HStack {
                VStack {
                    Text("平均バランス")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(averageBalance))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(averageBalance > 0 ? .red : .green)
                    Text("kcal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(averageBalance > 0 ? "摂取過多" : "消費過多")
                        .font(.caption)
                        .foregroundColor(averageBalance > 0 ? .red : .green)
                    Text(averageBalance > 0 ? "食事を控えめに" : "運動を増やす")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var adviceSection: some View {
        VStack(spacing: 15) {
            Text("アドバイス")
                .font(.headline)
            
            VStack(spacing: 10) {
                AdviceCard(
                    title: "体重管理",
                    message: viewModel.output.weightAdvice,
                    icon: "scalemass.fill",
                    color: .purple
                )
                
                AdviceCard(
                    title: "筋肉増強",
                    message: viewModel.output.muscleAdvice,
                    icon: "dumbbell.fill",
                    color: .green
                )
                
                AdviceCard(
                    title: "運動習慣",
                    message: viewModel.output.fitnessAdvice,
                    icon: "figure.run",
                    color: .blue
                )
                
                AdviceCard(
                    title: "栄養管理",
                    message: viewModel.output.nutritionAdvice,
                    icon: "fork.knife",
                    color: .orange
                )
            }
        }
    }
    

    

}

struct ProgressCircle: View {
    let title: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: progress)
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct AdviceCard: View {
    let title: String
    let message: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

 