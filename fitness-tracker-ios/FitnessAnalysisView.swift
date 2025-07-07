import SwiftUI
import Charts

struct FitnessAnalysisView: View {
    @StateObject private var analysisCalculator = FitnessAnalysisCalculator()
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedChartType: ChartType = .efficiency
    
    enum TimeRange: String, CaseIterable {
        case week = "1週間"
        case month = "1ヶ月"
        case threeMonths = "3ヶ月"
    }
    
    enum ChartType: String, CaseIterable {
        case efficiency = "効率分析"
        case calories = "カロリー"
        case bodyComposition = "体組成"
        case workoutIntensity = "筋トレ強度"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.1),
                        Color(red: 0.1, green: 0.05, blue: 0.15)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // ヘッダー
                        headerSection
                        
                        // 分析結果サマリー
                        if let result = analysisCalculator.analysisResult {
                            analysisSummarySection
                        }
                        
                        // チャート選択
                        chartSelectionSection
                        
                        // メイングラフ
                        mainChartSection
                        
                        // 詳細分析
                        detailedAnalysisSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                analysisCalculator.fetchAnalysisData()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("FITNESS")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("ANALYSIS")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.cyan)
                }
                
                Spacer()
                
                // 効率スコア
                if let result = analysisCalculator.analysisResult {
                    VStack(spacing: 2) {
                        Text("\(Int(result.efficiencyScore * 100))")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.green)
                        Text("効率")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            
            Text("筋トレ効率と体脂肪率の分析")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 5)
    }
    
    // MARK: - Analysis Summary Section
    private var analysisSummarySection: some View {
        Group {
            if let result = analysisCalculator.analysisResult {
                VStack(spacing: 15) {
                    Text("最適化提案")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 2), spacing: 15) {
                        AnalysisCard(
                            title: "カロリーサープラス",
                            value: "\(Int(result.optimalCalorieSurplus.isFinite ? result.optimalCalorieSurplus : 0.0))",
                            unit: "kcal",
                            icon: "plus.circle.fill",
                            color: .green
                        )
                        
                        AnalysisCard(
                            title: "筋トレ強度",
                            value: "\(Int((result.optimalWorkoutIntensity.isFinite ? result.optimalWorkoutIntensity : 0.0) * 100))",
                            unit: "%",
                            icon: "dumbbell.fill",
                            color: .orange
                        )
                        
                        AnalysisCard(
                            title: "タンパク質摂取",
                            value: "\(Int(result.recommendedProteinIntake.isFinite ? result.recommendedProteinIntake : 0.0))",
                            unit: "g",
                            icon: "leaf.fill",
                            color: .blue
                        )
                        
                        AnalysisCard(
                            title: "筋肉増加予測",
                            value: String(format: "%.1f", result.muscleGainPrediction.isFinite ? result.muscleGainPrediction : 0.0),
                            unit: "kg/月",
                            icon: "arrow.up.circle.fill",
                            color: .purple
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Chart Selection Section
    private var chartSelectionSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("グラフ表示")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Picker("期間", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            Picker("グラフタイプ", selection: $selectedChartType) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    // MARK: - Main Chart Section
    private var mainChartSection: some View {
        VStack(spacing: 15) {
            Text(chartTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            switch selectedChartType {
            case .efficiency:
                efficiencyChart
            case .calories:
                caloriesChart
            case .bodyComposition:
                bodyCompositionChart
            case .workoutIntensity:
                workoutIntensityChart
            }
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Charts
    
    private var efficiencyChart: some View {
        VStack(spacing: 10) {
            Chart {
                ForEach(filteredData) { dataPoint in
                    LineMark(
                        x: .value("日付", dataPoint.date),
                        y: .value("筋肉増加効率", dataPoint.muscleGainEfficiency)
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    LineMark(
                        x: .value("日付", dataPoint.date),
                        y: .value("脂肪減少効率", dataPoint.fatLossEfficiency)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                }
            }
            .frame(height: 250)
            .chartYScale(domain: 0...1)
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine()
                        .foregroundStyle(.white.opacity(0.2))
                    AxisTick()
                        .foregroundStyle(.white.opacity(0.5))
                    AxisValueLabel()
                        .foregroundStyle(.white)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: selectedTimeRange == .week ? .day : .weekOfYear)) { value in
                    AxisGridLine()
                        .foregroundStyle(.white.opacity(0.2))
                    AxisTick()
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            
            // 日付ラベル
            dateLabelsView
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // 日付ラベル用のView
    private var dateLabelsView: some View {
        let step = selectedTimeRange == .week ? 1 : 3
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        
        return HStack {
            ForEach(Array(filteredData.indices.enumerated()), id: \.offset) { _, index in
                if index % step == 0 {
                    Text(formatter.string(from: filteredData[index].date))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    if index < filteredData.count - step {
                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var caloriesChart: some View {
        VStack(spacing: 10) {
            Chart {
                ForEach(filteredData) { dataPoint in
                    LineMark(
                        x: .value("日付", dataPoint.date),
                        y: .value("摂取カロリー", dataPoint.caloriesIn)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    LineMark(
                        x: .value("日付", dataPoint.date),
                        y: .value("消費カロリー", dataPoint.caloriesOut)
                    )
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                }
            }
            .frame(height: 250)
            .chartYScale(domain: 0...3000)
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine()
                        .foregroundStyle(.white.opacity(0.2))
                    AxisTick()
                        .foregroundStyle(.white.opacity(0.5))
                    AxisValueLabel()
                        .foregroundStyle(.white)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: selectedTimeRange == .week ? .day : .weekOfYear)) { value in
                    AxisGridLine()
                        .foregroundStyle(.white.opacity(0.2))
                    AxisTick()
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            
            // 日付ラベル
            dateLabelsView
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var bodyCompositionChart: some View {
        VStack(spacing: 10) {
            Chart {
                ForEach(filteredData) { dataPoint in
                    LineMark(
                        x: .value("日付", dataPoint.date),
                        y: .value("体脂肪率", dataPoint.bodyFatPercentage)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                }
            }
            .frame(height: 250)
            .chartYScale(domain: 10...30)
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine()
                        .foregroundStyle(.white.opacity(0.2))
                    AxisTick()
                        .foregroundStyle(.white.opacity(0.5))
                    AxisValueLabel()
                        .foregroundStyle(.white)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: selectedTimeRange == .week ? .day : .weekOfYear)) { value in
                    AxisGridLine()
                        .foregroundStyle(.white.opacity(0.2))
                    AxisTick()
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            
            // 日付ラベル
            dateLabelsView
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var workoutIntensityChart: some View {
        VStack(spacing: 10) {
            Chart {
                ForEach(filteredData) { dataPoint in
                    BarMark(
                        x: .value("日付", dataPoint.date),
                        y: .value("筋トレ強度", dataPoint.workoutIntensity)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                }
            }
            .frame(height: 250)
            .chartYScale(domain: 0...1)
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine()
                        .foregroundStyle(.white.opacity(0.2))
                    AxisTick()
                        .foregroundStyle(.white.opacity(0.5))
                    AxisValueLabel()
                        .foregroundStyle(.white)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: selectedTimeRange == .week ? .day : .weekOfYear)) { value in
                    AxisGridLine()
                        .foregroundStyle(.white.opacity(0.2))
                    AxisTick()
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            
            // 日付ラベル
            dateLabelsView
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Detailed Analysis Section
    private var detailedAnalysisSection: some View {
        VStack(spacing: 15) {
            Text("詳細分析")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                AnalysisRow(
                    title: "筋肉増加効率",
                    value: String(format: "%.1f%%", averageMuscleGainEfficiency * 100),
                    color: .green
                )
                
                AnalysisRow(
                    title: "脂肪減少効率",
                    value: String(format: "%.1f%%", averageFatLossEfficiency * 100),
                    color: .red
                )
                
                AnalysisRow(
                    title: "平均カロリーサープラス",
                    value: "\(Int(averageCalorieSurplus)) kcal",
                    color: .blue
                )
                
                AnalysisRow(
                    title: "平均筋トレ強度",
                    value: String(format: "%.1f%%", averageWorkoutIntensity * 100),
                    color: .orange
                )
            }
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Computed Properties
    
    private var chartTitle: String {
        switch selectedChartType {
        case .efficiency:
            return "筋肉増加・脂肪減少効率"
        case .calories:
            return "カロリー摂取・消費"
        case .bodyComposition:
            return "体脂肪率推移"
        case .workoutIntensity:
            return "筋トレ強度"
        }
    }
    
    private var filteredData: [FitnessDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        
        let days: Int
        switch selectedTimeRange {
        case .week:
            days = 7
        case .month:
            days = 30
        case .threeMonths:
            days = 90
        }
        
        // 指定された日数分のデータを取得（今日を基準）
        let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: today) ?? today
        
        return analysisCalculator.fitnessData.filter { dataPoint in
            dataPoint.date >= startDate && dataPoint.date <= today
        }
    }
    
    private var averageMuscleGainEfficiency: Double {
        guard !filteredData.isEmpty else { return 0.0 }
        return filteredData.reduce(0) { $0 + $1.muscleGainEfficiency } / Double(filteredData.count)
    }
    
    private var averageFatLossEfficiency: Double {
        guard !filteredData.isEmpty else { return 0.0 }
        return filteredData.reduce(0) { $0 + $1.fatLossEfficiency } / Double(filteredData.count)
    }
    
    private var averageCalorieSurplus: Double {
        guard !filteredData.isEmpty else { return 0.0 }
        return filteredData.reduce(0) { $0 + ($1.caloriesIn - $1.caloriesOut) } / Double(filteredData.count)
    }
    
    private var averageWorkoutIntensity: Double {
        guard !filteredData.isEmpty else { return 0.0 }
        return filteredData.reduce(0) { $0 + $1.workoutIntensity } / Double(filteredData.count)
    }
}

// MARK: - Supporting Views

struct AnalysisCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(unit)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct AnalysisRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.03))
        )
    }
}

#Preview {
    FitnessAnalysisView()
} 