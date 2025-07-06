import SwiftUI
import HealthKit

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    
    init(
        healthKitManager: HealthKitManager,
        bodyCompositionManager: BodyCompositionManager,
        progressManager: ProgressManager
    ) {
        self._viewModel = StateObject(wrappedValue: DashboardViewModel(
            healthKitManager: healthKitManager,
            bodyCompositionManager: bodyCompositionManager,
            progressManager: progressManager
        ))
    }
    
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
            .navigationTitle("筋トレダッシュボード")
            .refreshable {
                await viewModel.refreshData()
            }
            .overlay(
                Group {
                    if viewModel.output.isLoading {
                        ProgressView("データを更新中...")
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                }
            )
        }
    }
    
    private var headerSection: some View {
        VStack {
            Text("Strength Tracker")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("筋トレ専用フィットネスアプリ")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(viewModel.output.currentDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var overallProgressSection: some View {
        VStack(spacing: 15) {
            Text("筋トレ進捗")
                .font(.title2)
                .fontWeight(.bold)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 150, height: 150)
                
                Circle()
                    .trim(from: 0, to: viewModel.output.overallProgress)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: viewModel.output.overallProgress)
                
                VStack {
                    Text("\(Int(viewModel.output.overallProgress * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("完了")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var todaySummarySection: some View {
        VStack(spacing: 15) {
            Text("今週の筋トレサマリー")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                SummaryCard(
                    title: "筋トレ回数",
                    value: "\(viewModel.output.weeklyWorkoutCount)",
                    unit: "回",
                    icon: "dumbbell.fill",
                    color: .orange
                )
                
                SummaryCard(
                    title: "心拍数",
                    value: "\(Int(viewModel.output.heartRate))",
                    unit: "BPM",
                    icon: "heart.fill",
                    color: .red
                )
                
                SummaryCard(
                    title: "消費カロリー",
                    value: "\(Int(viewModel.output.activeEnergy))",
                    unit: "kcal",
                    icon: "flame.fill",
                    color: .orange
                )
                
                SummaryCard(
                    title: "平均時間",
                    value: "\(Int(viewModel.output.averageWorkoutDuration / 60))",
                    unit: "分",
                    icon: "clock.fill",
                    color: .purple
                )
            }
        }
    }
    
    private var bodyCompositionSection: some View {
        VStack(spacing: 15) {
            Text("体組成")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                SummaryCard(
                    title: "体重",
                    value: "\(String(format: "%.1f", viewModel.output.currentWeight))",
                    unit: "kg",
                    icon: "scalemass.fill",
                    color: .purple
                )
                
                SummaryCard(
                    title: "筋肉量",
                    value: "\(String(format: "%.1f", viewModel.output.currentMuscleMass))",
                    unit: "kg",
                    icon: "dumbbell.fill",
                    color: .green
                )
                
                SummaryCard(
                    title: "体脂肪率",
                    value: "\(String(format: "%.1f", viewModel.output.currentBodyFatPercentage))",
                    unit: "%",
                    icon: "chart.pie.fill",
                    color: .orange
                )
                
                SummaryCard(
                    title: "基礎代謝",
                    value: "\(Int(viewModel.output.currentBasalMetabolicRate))",
                    unit: "kcal",
                    icon: "flame.fill",
                    color: .red
                )
            }
        }
    }
    
    private var workoutSummarySection: some View {
        VStack(spacing: 15) {
            Text("筋トレサマリー")
                .font(.headline)
            
            if viewModel.output.isWorkoutActive {
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading) {
                        Text("筋トレ中")
                            .font(.headline)
                            .foregroundColor(.orange)
                        Text("現在筋トレセッションを実行中です")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("停止") {
                        viewModel.endWorkout()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
            } else {
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("筋トレを開始")
                            .font(.headline)
                        Text("タップして筋トレを記録")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("開始") {
                        viewModel.startWorkout()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
        }
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