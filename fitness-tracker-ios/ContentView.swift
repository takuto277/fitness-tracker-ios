//
//  ContentView.swift
//  fitness-tracker-ios
//
//  Created by 小野拓人 on 2025/06/28.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var goalManager = GoalManager()
    @StateObject private var workoutManager = WorkoutManager()
    @StateObject private var nutritionManager = NutritionManager()
    @State private var selectedTab = 0
    
    var body: some View {
        if !healthKitManager.isHealthKitAvailable {
            HealthKitUnavailableView()
        } else if !healthKitManager.isAuthorized {
            AuthorizationView(healthKitManager: healthKitManager)
        } else {
            MainTabView(
                healthKitManager: healthKitManager,
                goalManager: goalManager,
                workoutManager: workoutManager,
                nutritionManager: nutritionManager
            )
        }
    }
}

struct MainTabView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @ObservedObject var goalManager: GoalManager
    @ObservedObject var workoutManager: WorkoutManager
    @ObservedObject var nutritionManager: NutritionManager
    
    var body: some View {
        TabView {
            // ダッシュボード
            DashboardView(
                healthKitManager: healthKitManager,
                goalManager: goalManager,
                workoutManager: workoutManager
            )
            .tabItem {
                Image(systemName: "chart.bar.fill")
                Text("ダッシュボード")
            }
            
            // 目標管理
            GoalsView(goalManager: goalManager)
                .tabItem {
                    Image(systemName: "target")
                    Text("目標")
                }
            
            // ワークアウト
            WorkoutView(workoutManager: workoutManager)
                .tabItem {
                    Image(systemName: "dumbbell.fill")
                    Text("ワークアウト")
                }
            
            // 栄養管理
            NutritionView(nutritionManager: nutritionManager)
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("栄養")
                }
            
            // 設定
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("設定")
                }
        }
        .onAppear {
            // データを更新
            healthKitManager.fetchTodayData()
            workoutManager.fetchWorkouts()
            nutritionManager.fetchTodayNutrition()
            
            // 目標の進捗を更新
            goalManager.updateGoalProgress(type: .steps, currentValue: Double(healthKitManager.stepCount))
            goalManager.updateGoalProgress(type: .calories, currentValue: healthKitManager.activeEnergy)
            goalManager.updateGoalProgress(type: .exercise, currentValue: workoutManager.weeklyWorkoutMinutes)
            goalManager.updateGoalProgress(type: .water, currentValue: nutritionManager.todayNutrition?.water ?? 0)
        }
    }
}

struct DashboardView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @ObservedObject var goalManager: GoalManager
    @ObservedObject var workoutManager: WorkoutManager
    
    var body: some View {
        NavigationView {
            ScrollView(content: {
                VStack(spacing: 20) {
                    // ヘッダー
                    VStack {
                        Text("HealthKit Fit Journey")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("2ヶ月で健康的なライフスタイルを確立")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(DateUtil.shared.formatJapaneseDate(Date()))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // 全体進捗
                    VStack(alignment: .leading, spacing: 10) {
                        Text("全体進捗")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ProgressView(value: goalManager.getOverallProgress())
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .padding(.horizontal)
                        
                        Text("\(Int(goalManager.getOverallProgress() * 100))% 完了")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // 今日のメトリクス
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                        MetricCard(
                            title: "歩数",
                            value: "\(healthKitManager.stepCount)",
                            unit: "歩",
                            icon: "figure.walk",
                            color: .blue,
                            progress: goalManager.goals.first { $0.type == .steps }?.progress ?? 0
                        )
                        
                        MetricCard(
                            title: "心拍数",
                            value: String(format: "%.0f", healthKitManager.heartRate),
                            unit: "BPM",
                            icon: "heart.fill",
                            color: .red,
                            progress: 0
                        )
                        
                        MetricCard(
                            title: "消費カロリー",
                            value: String(format: "%.0f", healthKitManager.activeEnergy),
                            unit: "kcal",
                            icon: "flame.fill",
                            color: .orange,
                            progress: goalManager.goals.first { $0.type == .calories }?.progress ?? 0
                        )
                        
                        MetricCard(
                            title: "運動時間",
                            value: String(format: "%.0f", workoutManager.weeklyWorkoutMinutes),
                            unit: "分",
                            icon: "dumbbell.fill",
                            color: .green,
                            progress: goalManager.goals.first { $0.type == .exercise }?.progress ?? 0
                        )
                    }
                    .padding(.horizontal)
                    
                    // 最近の目標達成
                    if !goalManager.getCompletedGoals().isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("最近の達成")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(goalManager.getCompletedGoals().prefix(3), id: \.id) { goal in
                                HStack {
                                    Image(systemName: goal.type.icon)
                                        .foregroundColor(goal.type.color)
                                    Text(goal.title)
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    
                    // 更新ボタン
                    Button(action: {
                        healthKitManager.fetchTodayData()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("データを更新")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            })
            .navigationBarHidden(true)
        }
    }
}

struct MetricCard: View {
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
            
            if progress > 0 {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                    .frame(height: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct HealthKitUnavailableView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "xmark.circle")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            Text("HealthKitが利用できません")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("このアプリはHealthKitをサポートするデバイスで実行する必要があります。")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct AuthorizationView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            Text("HealthKitの権限が必要です")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("このアプリは健康データを表示するためにHealthKitへのアクセス権限が必要です。")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: {
                healthKitManager.requestAuthorization()
            }) {
                HStack {
                    Image(systemName: "heart.fill")
                    Text("権限を許可する")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
