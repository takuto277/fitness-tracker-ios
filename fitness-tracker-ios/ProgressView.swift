import SwiftUI
import Charts

struct ProgressAnalysisView: View {
    @ObservedObject var progressTracker: ProgressTracker
    @State private var selectedTimeRange: TimeRange = .week
    
    enum TimeRange: String, CaseIterable {
        case week = "週間"
        case month = "月間"
        case threeMonths = "3ヶ月"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 全体進捗サマリー
                    VStack(spacing: 15) {
                        Text("全体進捗")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                                .frame(width: 150, height: 150)
                            
                            Circle()
                                .trim(from: 0, to: progressTracker.getOverallProgress())
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                                .frame(width: 150, height: 150)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 1.0), value: progressTracker.getOverallProgress())
                            
                            VStack {
                                Text("\(Int(progressTracker.getOverallProgress() * 100))%")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("完了")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("ダイエット × 筋トレ進捗")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // 時間範囲選択
                    Picker("時間範囲", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // 体重と筋肉量の変化
                    VStack(spacing: 15) {
                        Text("身体組成の変化")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                            ProgressMetricCard(
                                title: "体重変化",
                                value: getWeightChange(),
                                unit: "kg",
                                icon: "scalemass",
                                color: .purple,
                                progress: progressTracker.getWeightProgress()
                            )
                            
                            ProgressMetricCard(
                                title: "筋肉量変化",
                                value: getMuscleChange(),
                                unit: "kg",
                                icon: "dumbbell.fill",
                                color: .green,
                                progress: progressTracker.getMuscleGainProgress()
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // 運動進捗
                    VStack(spacing: 15) {
                        Text("運動進捗")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                            ProgressMetricCard(
                                title: "総運動時間",
                                value: getWorkoutMinutes(),
                                unit: "分",
                                icon: "figure.mixed.cardio",
                                color: .blue,
                                progress: progressTracker.getWorkoutProgress()
                            )
                            
                            ProgressMetricCard(
                                title: "筋トレ時間",
                                value: getStrengthMinutes(),
                                unit: "分",
                                icon: "dumbbell.fill",
                                color: .orange,
                                progress: progressTracker.getStrengthProgress()
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // 進捗グラフ
                    if !progressTracker.progressData.isEmpty {
                        VStack(spacing: 15) {
                            Text("体重と筋肉量の推移")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ProgressChart(data: progressTracker.progressData)
                                .frame(height: 200)
                                .padding(.horizontal)
                        }
                    }
                    
                    // 詳細分析
                    VStack(spacing: 15) {
                        Text("詳細分析")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            AnalysisRow(
                                title: "体重目標達成率",
                                value: "\(Int(progressTracker.getWeightProgress() * 100))%",
                                color: .purple
                            )
                            
                            AnalysisRow(
                                title: "筋肉量目標達成率",
                                value: "\(Int(progressTracker.getMuscleGainProgress() * 100))%",
                                color: .green
                            )
                            
                            AnalysisRow(
                                title: "運動目標達成率",
                                value: "\(Int(progressTracker.getWorkoutProgress() * 100))%",
                                color: .blue
                            )
                            
                            AnalysisRow(
                                title: "筋トレ目標達成率",
                                value: "\(Int(progressTracker.getStrengthProgress() * 100))%",
                                color: .orange
                            )
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // アドバイス
                    VStack(spacing: 15) {
                        Text("アドバイス")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            AdviceCard(
                                title: "体重管理",
                                description: getWeightAdvice(),
                                icon: "scalemass",
                                color: .purple
                            )
                            
                            AdviceCard(
                                title: "筋トレ",
                                description: getStrengthAdvice(),
                                icon: "dumbbell.fill",
                                color: .orange
                            )
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("進捗分析")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        progressTracker.fetchProgressData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
    
    // ヘルパーメソッド
    private func getWeightChange() -> String {
        guard let currentWeight = progressTracker.progressData.last?.weight,
              let initialWeight = progressTracker.progressData.first?.weight else {
            return "0.0"
        }
        let change = currentWeight - initialWeight
        return String(format: "%.1f", change)
    }
    
    private func getMuscleChange() -> String {
        guard let currentMuscle = progressTracker.progressData.last?.muscleMass,
              let initialMuscle = progressTracker.progressData.first?.muscleMass else {
            return "0.0"
        }
        let change = currentMuscle - initialMuscle
        return String(format: "%.1f", change)
    }
    
    private func getWorkoutMinutes() -> String {
        guard let weekly = progressTracker.weeklyProgress else { return "0" }
        return "\(Int(weekly.workoutMinutes))"
    }
    
    private func getStrengthMinutes() -> String {
        guard let weekly = progressTracker.weeklyProgress else { return "0" }
        return "\(Int(weekly.strengthWorkoutMinutes))"
    }
    
    private func getWeightAdvice() -> String {
        let progress = progressTracker.getWeightProgress()
        if progress >= 0.8 {
            return "素晴らしい進捗です！現在のペースを維持しましょう。"
        } else if progress >= 0.5 {
            return "順調に進んでいます。食事管理と運動のバランスを保ちましょう。"
        } else {
            return "もう少しペースアップが必要です。有酸素運動を増やしてみましょう。"
        }
    }
    
    private func getStrengthAdvice() -> String {
        let progress = progressTracker.getStrengthProgress()
        if progress >= 0.8 {
            return "筋トレが順調です！強度を上げてみましょう。"
        } else if progress >= 0.5 {
            return "筋トレの頻度を少し増やしてみましょう。"
        } else {
            return "筋トレの時間を確保しましょう。週3回以上を目標に。"
        }
    }
}

struct ProgressMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let progress: Double
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct AnalysisRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct AdviceCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ProgressChart: View {
    let data: [ProgressData]
    
    var body: some View {
        Chart {
            ForEach(data.indices, id: \.self) { index in
                if let weight = data[index].weight {
                    LineMark(
                        x: .value("日付", data[index].date),
                        y: .value("体重", weight)
                    )
                    .foregroundStyle(.purple)
                    .symbol(.circle)
                }
                
                if let muscle = data[index].muscleMass {
                    LineMark(
                        x: .value("日付", data[index].date),
                        y: .value("筋肉量", muscle)
                    )
                    .foregroundStyle(.green)
                    .symbol(.square)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartLegend(position: .bottom) {
            HStack {
                HStack {
                    Circle()
                        .fill(.purple)
                        .frame(width: 10, height: 10)
                    Text("体重")
                }
                HStack {
                    Rectangle()
                        .fill(.green)
                        .frame(width: 10, height: 10)
                    Text("筋肉量")
                }
            }
        }
    }
}

#Preview {
    ProgressAnalysisView(progressTracker: ProgressTracker())
} 