import SwiftUI
import Charts

// MARK: - Weight Chart
struct WeightChartView: View {
    let progressData: [ProgressData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("体重推移")
                .font(.headline)
            
            Chart(progressData) { data in
                LineMark(
                    x: .value("日付", data.date),
                    y: .value("体重", data.weight)
                )
                .foregroundStyle(.purple)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                AreaMark(
                    x: .value("日付", data.date),
                    y: .value("体重", data.weight)
                )
                .foregroundStyle(.purple.opacity(0.1))
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel("\(value.as(Double.self)?.formatted(.number.precision(.fractionLength(1))) ?? "")kg")
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
}

// MARK: - Muscle Mass Chart
struct MuscleMassChartView: View {
    let progressData: [ProgressData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("筋肉量推移")
                .font(.headline)
            
            Chart(progressData) { data in
                LineMark(
                    x: .value("日付", data.date),
                    y: .value("筋肉量", data.muscleMass)
                )
                .foregroundStyle(.green)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                PointMark(
                    x: .value("日付", data.date),
                    y: .value("筋肉量", data.muscleMass)
                )
                .foregroundStyle(.green)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel("\(value.as(Double.self)?.formatted(.number.precision(.fractionLength(1))) ?? "")kg")
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(15)
    }
}

// MARK: - Calorie Balance Chart
struct CalorieBalanceChartView: View {
    let progressData: [ProgressData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("カロリーバランス")
                .font(.headline)
            
            Chart(progressData) { data in
                BarMark(
                    x: .value("日付", data.date),
                    y: .value("カロリー", data.caloriesConsumed)
                )
                .foregroundStyle(.blue)
                .position(by: .value("タイプ", "摂取"))
                
                BarMark(
                    x: .value("日付", data.date),
                    y: .value("カロリー", data.caloriesBurned)
                )
                .foregroundStyle(.orange)
                .position(by: .value("タイプ", "消費"))
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel("\(Int(value.as(Double.self) ?? 0))kcal")
                }
            }
            .chartLegend(position: .bottom)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
}

// MARK: - Nutrition Pie Chart
struct NutritionPieChartView: View {
    let proteinPercentage: Double
    let carbsPercentage: Double
    let fatPercentage: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("栄養バランス")
                .font(.headline)
            
            HStack {
                // 円グラフ
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                        .frame(width: 120, height: 120)
                    
                    // タンパク質
                    Circle()
                        .trim(from: 0, to: proteinPercentage)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                    
                    // 炭水化物
                    Circle()
                        .trim(from: proteinPercentage, to: proteinPercentage + carbsPercentage)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                    
                    // 脂質
                    Circle()
                        .trim(from: proteinPercentage + carbsPercentage, to: 1.0)
                        .stroke(Color.yellow, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                }
                
                // 凡例
                VStack(alignment: .leading, spacing: 8) {
                    LegendItem(color: .green, label: "タンパク質", percentage: proteinPercentage)
                    LegendItem(color: .blue, label: "炭水化物", percentage: carbsPercentage)
                    LegendItem(color: .yellow, label: "脂質", percentage: fatPercentage)
                }
                .padding(.leading)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
}

// MARK: - Legend Item
struct LegendItem: View {
    let color: Color
    let label: String
    let percentage: Double
    
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            Text(label)
                .font(.caption)
            
            Text("\(Int(percentage * 100))%")
                .font(.caption)
                .fontWeight(.bold)
        }
    }
}

// MARK: - Muscle Gain Efficiency Chart
struct MuscleGainEfficiencyChartView: View {
    let efficiency: Double
    let calorieBalance: Double
    let proteinIntake: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("筋肉増加効率")
                .font(.headline)
            
            // 効率ゲージ
            VStack(spacing: 8) {
                HStack {
                    Text("効率")
                        .font(.caption)
                    Spacer()
                    Text("\(Int(efficiency * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 20)
                            .cornerRadius(10)
                        
                        Rectangle()
                            .fill(efficiencyColor)
                            .frame(width: geometry.size.width * efficiency, height: 20)
                            .cornerRadius(10)
                    }
                }
                .frame(height: 20)
            }
            
            // 詳細指標
            HStack(spacing: 20) {
                VStack {
                    Text("カロリー収支")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(calorieBalance))kcal")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(calorieBalanceColor)
                }
                
                VStack {
                    Text("タンパク質")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(proteinIntake))g")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(proteinColor)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var efficiencyColor: Color {
        if efficiency >= 0.8 { return .green }
        else if efficiency >= 0.6 { return .blue }
        else if efficiency >= 0.4 { return .orange }
        else { return .red }
    }
    
    private var calorieBalanceColor: Color {
        if calorieBalance >= 200 && calorieBalance <= 500 { return .green }
        else if calorieBalance > 500 { return .orange }
        else { return .red }
    }
    
    private var proteinColor: Color {
        if proteinIntake >= 120 { return .green }
        else if proteinIntake >= 80 { return .orange }
        else { return .red }
    }
}

// MARK: - Workout Frequency Chart
struct WorkoutFrequencyChartView: View {
    let weeklyFrequency: Int
    let recommendedFrequency: Int
    let averageDuration: TimeInterval
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("筋トレ頻度分析")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack {
                    Text("現在")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(weeklyFrequency)回/週")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(frequencyColor)
                }
                
                VStack {
                    Text("推奨")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(recommendedFrequency)回/週")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                VStack {
                    Text("平均時間")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(averageDuration / 60))分")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
            }
            
            // 頻度バー
            HStack(spacing: 5) {
                ForEach(1...7, id: \.self) { day in
                    Rectangle()
                        .fill(day <= weeklyFrequency ? Color.green : Color.gray.opacity(0.3))
                        .frame(height: 30)
                        .cornerRadius(5)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var frequencyColor: Color {
        if weeklyFrequency >= recommendedFrequency { return .green }
        else if weeklyFrequency >= 3 { return .orange }
        else { return .red }
    }
}

// MARK: - Calorie Balance Trend Chart
struct CalorieBalanceTrendChartView: View {
    let dailyBalances: [Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("カロリー収支トレンド")
                .font(.headline)
            
            Chart(Array(dailyBalances.enumerated()), id: \.offset) { index, balance in
                BarMark(
                    x: .value("日", index + 1),
                    y: .value("収支", balance)
                )
                .foregroundStyle(balanceColor(for: balance))
            }
            .frame(height: 150)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel("\(value.as(Int.self) ?? 0)日")
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel("\(Int(value.as(Double.self) ?? 0))kcal")
                }
            }
            
            // 週間平均
            HStack {
                Text("週間平均:")
                    .font(.caption)
                Text("\(Int(weeklyAverage))kcal")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(weeklyAverageColor)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var weeklyAverage: Double {
        guard !dailyBalances.isEmpty else { return 0 }
        return dailyBalances.reduce(0, +) / Double(dailyBalances.count)
    }
    
    private func balanceColor(for balance: Double) -> Color {
        if balance >= 200 && balance <= 500 { return .green }
        else if balance > 500 { return .orange }
        else if balance < -200 { return .red }
        else { return .blue }
    }
    
    private var weeklyAverageColor: Color {
        if weeklyAverage >= 200 && weeklyAverage <= 500 { return .green }
        else if weeklyAverage > 500 { return .orange }
        else if weeklyAverage < -200 { return .red }
        else { return .blue }
    }
} 