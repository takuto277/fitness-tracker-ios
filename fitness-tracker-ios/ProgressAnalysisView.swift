import SwiftUI
import HealthKit

struct ProgressAnalysisView: View {
    @EnvironmentObject var progressManager: ProgressManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var bodyCompositionManager: BodyCompositionManager
    @State private var selectedPeriod: AnalysisPeriod = .week
    
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
                loadData()
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
                    progress: progressManager.weightProgress,
                    color: .purple
                )
                
                ProgressCircle(
                    title: "筋肉量",
                    progress: progressManager.muscleProgress,
                    color: .green
                )
                
                ProgressCircle(
                    title: "フィットネス",
                    progress: progressManager.fitnessProgress,
                    color: .blue
                )
                
                ProgressCircle(
                    title: "栄養",
                    progress: progressManager.nutritionProgress,
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
                    selectedPeriod = period
                    loadData()
                }) {
                    Text(period.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            selectedPeriod == period ? Color.blue : Color.clear
                        )
                        .foregroundColor(
                            selectedPeriod == period ? .white : .primary
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
        VStack(spacing: 10) {
            Text("体重・筋肉量の推移")
                .font(.subheadline)
                .fontWeight(.bold)
            
            // 簡易的なグラフ表示（実際のアプリではChartKitを使用）
            VStack(spacing: 5) {
                ForEach(progressData.prefix(7), id: \.id) { data in
                    HStack {
                        Text(DateUtil.shared.formatJapaneseDate(data.date, format: "MM/dd"))
                            .font(.caption)
                            .frame(width: 50, alignment: .leading)
                        
                        Text("体重: \(String(format: "%.1f", data.weight))kg")
                            .font(.caption)
                            .frame(width: 80, alignment: .leading)
                        
                        Text("筋肉: \(String(format: "%.1f", data.muscleMass))kg")
                            .font(.caption)
                            .frame(width: 80, alignment: .leading)
                        
                        Spacer()
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(5)
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var fitnessNutritionSection: some View {
        VStack(spacing: 10) {
            Text("運動・栄養の推移")
                .font(.subheadline)
                .fontWeight(.bold)
            
            VStack(spacing: 5) {
                ForEach(progressData.prefix(7), id: \.id) { data in
                    HStack {
                        Text(DateUtil.shared.formatJapaneseDate(data.date, format: "MM/dd"))
                            .font(.caption)
                            .frame(width: 50, alignment: .leading)
                        
                        Text("運動: \(Int(data.workoutDuration / 60))分")
                            .font(.caption)
                            .frame(width: 70, alignment: .leading)
                        
                        Text("消費: \(Int(data.caloriesBurned))kcal")
                            .font(.caption)
                            .frame(width: 80, alignment: .leading)
                        
                        Text("摂取: \(Int(data.caloriesConsumed))kcal")
                            .font(.caption)
                            .frame(width: 80, alignment: .leading)
                        
                        Spacer()
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(5)
                }
            }
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
            
            let averageBalance = progressData.isEmpty ? 0 : progressData.map { $0.calorieBalance }.reduce(0, +) / Double(progressData.count)
            
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
                    message: weightAdvice,
                    icon: "scalemass.fill",
                    color: .purple
                )
                
                AdviceCard(
                    title: "筋肉増強",
                    message: muscleAdvice,
                    icon: "dumbbell.fill",
                    color: .green
                )
                
                AdviceCard(
                    title: "運動習慣",
                    message: fitnessAdvice,
                    icon: "figure.run",
                    color: .blue
                )
                
                AdviceCard(
                    title: "栄養管理",
                    message: nutritionAdvice,
                    icon: "fork.knife",
                    color: .orange
                )
            }
        }
    }
    
    private var progressData: [ProgressData] {
        switch selectedPeriod {
        case .week:
            return progressManager.weeklyData
        case .month:
            return progressManager.monthlyData
        }
    }
    
    private func loadData() {
        switch selectedPeriod {
        case .week:
            progressManager.fetchWeeklyData()
        case .month:
            progressManager.fetchMonthlyData()
        }
    }
    
    // アドバイス生成
    private var weightAdvice: String {
        if progressManager.weightProgress < 0.3 {
            return "体重の変化が少ないです。食事と運動のバランスを見直しましょう。"
        } else if progressManager.weightProgress > 0.8 {
            return "素晴らしい進捗です！この調子で継続しましょう。"
        } else {
            return "順調に進んでいます。目標に向かって頑張りましょう。"
        }
    }
    
    private var muscleAdvice: String {
        if progressManager.muscleProgress < 0.3 {
            return "筋肉量の増加が少ないです。筋トレの頻度と強度を上げましょう。"
        } else if progressManager.muscleProgress > 0.8 {
            return "筋肉量が順調に増加しています！継続しましょう。"
        } else {
            return "筋肉量は徐々に増加しています。タンパク質の摂取も意識しましょう。"
        }
    }
    
    private var fitnessAdvice: String {
        if progressManager.fitnessProgress < 0.3 {
            return "運動習慣が不足しています。週3回以上の運動を心がけましょう。"
        } else if progressManager.fitnessProgress > 0.8 {
            return "素晴らしい運動習慣です！この調子で継続しましょう。"
        } else {
            return "運動習慣は良好です。さらに強度を上げることを検討しましょう。"
        }
    }
    
    private var nutritionAdvice: String {
        if progressManager.nutritionProgress < 0.3 {
            return "栄養管理が不十分です。カロリーと栄養素のバランスを見直しましょう。"
        } else if progressManager.nutritionProgress > 0.8 {
            return "栄養管理が素晴らしいです！この調子で継続しましょう。"
        } else {
            return "栄養管理は良好です。さらに細かい栄養素にも注目しましょう。"
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

enum AnalysisPeriod: CaseIterable {
    case week, month
    
    var displayName: String {
        switch self {
        case .week:
            return "週間"
        case .month:
            return "月間"
        }
    }
} 