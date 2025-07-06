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