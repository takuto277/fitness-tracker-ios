import SwiftUI
import HealthKit

struct DashboardView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var bodyCompositionManager: BodyCompositionManager
    @EnvironmentObject var progressManager: ProgressManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // ヘッダー
                    headerSection
                    
                    // 全体進捗
                    overallProgressSection
                    
                    // 今日のサマリー
                    todaySummarySection
                    
                    // 体組成サマリー
                    bodyCompositionSection
                    
                    // 運動サマリー
                    workoutSummarySection
                }
                .padding()
            }
            .navigationTitle("ダッシュボード")
            .refreshable {
                refreshData()
            }
        }
    }
    
    private var headerSection: some View {
        VStack {
            Text("HealthKit Fit Journey")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("ダイエット × 筋トレの両立")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(DateUtil.shared.formatJapaneseDate(Date()))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var overallProgressSection: some View {
        VStack(spacing: 15) {
            Text("全体進捗")
                .font(.title2)
                .fontWeight(.bold)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 150, height: 150)
                
                Circle()
                    .trim(from: 0, to: progressManager.overallProgress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: progressManager.overallProgress)
                
                VStack {
                    Text("\(Int(progressManager.overallProgress * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("完了")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var todaySummarySection: some View {
        VStack(spacing: 15) {
            Text("今日のサマリー")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                SummaryCard(
                    title: "歩数",
                    value: "\(healthKitManager.stepCount)",
                    unit: "歩",
                    icon: "figure.walk",
                    color: .green
                )
                
                SummaryCard(
                    title: "心拍数",
                    value: "\(Int(healthKitManager.heartRate))",
                    unit: "BPM",
                    icon: "heart.fill",
                    color: .red
                )
                
                SummaryCard(
                    title: "消費カロリー",
                    value: "\(Int(healthKitManager.activeEnergy))",
                    unit: "kcal",
                    icon: "flame.fill",
                    color: .orange
                )
                
                SummaryCard(
                    title: "距離",
                    value: "\(String(format: "%.1f", healthKitManager.distance / 1000))",
                    unit: "km",
                    icon: "location.fill",
                    color: .blue
                )
            }
        }
    }
    
    private var bodyCompositionSection: some View {
        VStack(spacing: 15) {
            Text("体組成サマリー")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                SummaryCard(
                    title: "体重",
                    value: "\(String(format: "%.1f", bodyCompositionManager.currentWeight))",
                    unit: "kg",
                    icon: "scalemass.fill",
                    color: .purple
                )
                
                SummaryCard(
                    title: "筋肉量",
                    value: "\(String(format: "%.1f", bodyCompositionManager.currentMuscleMass))",
                    unit: "kg",
                    icon: "dumbbell.fill",
                    color: .green
                )
                
                SummaryCard(
                    title: "体脂肪率",
                    value: "\(String(format: "%.1f", bodyCompositionManager.currentBodyFatPercentage))",
                    unit: "%",
                    icon: "chart.pie.fill",
                    color: .orange
                )
                
                SummaryCard(
                    title: "基礎代謝",
                    value: "\(Int(bodyCompositionManager.currentBasalMetabolicRate))",
                    unit: "kcal",
                    icon: "flame.fill",
                    color: .red
                )
            }
        }
    }
    
    private var workoutSummarySection: some View {
        VStack(spacing: 15) {
            Text("運動サマリー")
                .font(.headline)
            
            if healthKitManager.isWorkoutActive {
                HStack {
                    Image(systemName: "figure.run")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading) {
                        Text("運動中")
                            .font(.headline)
                            .foregroundColor(.green)
                        Text("現在ワークアウトを実行中です")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("停止") {
                        healthKitManager.endWorkout()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
            } else {
                HStack {
                    Image(systemName: "figure.run")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("運動を開始")
                            .font(.headline)
                        Text("タップして運動を記録")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("開始") {
                        // 運動開始画面に遷移
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
    
    private func refreshData() {
        healthKitManager.fetchTodayData()
        bodyCompositionManager.fetchLatestBodyCompositionData()
        progressManager.calculateProgress()
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
} 