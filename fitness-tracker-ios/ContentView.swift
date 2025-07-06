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
    @StateObject private var bodyCompositionManager = BodyCompositionManager()
    @StateObject private var nutritionManager = NutritionManager.shared
    @StateObject private var progressManager = ProgressManager()
    
    var body: some View {
        TabView {
            // 統合ダッシュボード
            DashboardView(
                healthKitManager: healthKitManager,
                bodyCompositionManager: bodyCompositionManager,
                progressManager: progressManager
            )
            .tabItem {
                Image(systemName: "house.fill")
                Text("ダッシュボード")
            }
            
            // リアルタイム運動
            RealTimeWorkoutView(healthKitManager: healthKitManager)
                .tabItem {
                    Image(systemName: "figure.run")
                    Text("リアルタイム運動")
                }
            
            // 体組成管理
            BodyCompositionView(bodyCompositionManager: bodyCompositionManager)
                .tabItem {
                    Image(systemName: "scalemass.fill")
                    Text("体組成")
                }
            
            // 栄養分析
            NutritionAnalysisView()
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("栄養分析")
                }
            
            // 進捗分析
            ProgressAnalysisView(
                progressManager: progressManager,
                healthKitManager: healthKitManager,
                bodyCompositionManager: bodyCompositionManager
            )
            .tabItem {
                Image(systemName: "chart.line.uptrend.xyaxis")
                Text("進捗分析")
            }
        }
        .accentColor(.blue)
    }
}

// リアルタイム運動画面
struct RealTimeWorkoutView: View {
    @StateObject private var viewModel: RealTimeWorkoutViewModel
    
    init(healthKitManager: HealthKitManager) {
        self._viewModel = StateObject(wrappedValue: RealTimeWorkoutViewModel(
            healthKitManager: healthKitManager
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // ワークアウトタイプ選択
                    if !viewModel.output.isWorkoutActive {
                        workoutTypeSelector
                    }
                    
                    // リアルタイムデータ表示
                    if viewModel.output.isWorkoutActive {
                        realTimeDataView
                        
                        // 筋トレ専用セクション
                        if viewModel.output.selectedWorkoutType == .traditionalStrengthTraining {
                            strengthTrainingSection
                        }
                    }
                    
                    // コントロールボタン
                    controlButtons
                }
                .padding()
            }
            .navigationTitle("リアルタイム運動")
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                if viewModel.output.isWorkoutActive {
                    viewModel.updateWorkoutData()
                }
            }
        }
    }
    
    private var workoutTypeSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ワークアウトタイプ")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                ForEach(RealTimeWorkoutViewModel.availableWorkoutTypes, id: \.self) { type in
                    Button(action: {
                        viewModel.selectWorkoutType(type)
                    }) {
                        VStack {
                            Image(systemName: type.icon)
                                .font(.title2)
                                .foregroundColor(type.color)
                            Text(type.displayName)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        .frame(height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(viewModel.output.selectedWorkoutType == type ? type.color.opacity(0.2) : Color.gray.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(viewModel.output.selectedWorkoutType == type ? type.color : Color.clear, lineWidth: 2)
                                )
                        )
                    }
                }
            }
        }
    }
    
    private var realTimeDataView: some View {
        VStack(spacing: 15) {
            // 時間表示
            Text(viewModel.timeString(from: viewModel.output.workoutDuration))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.blue)
            
            // リアルタイムデータ
            HStack(spacing: 20) {
                DataCard(
                    title: "心拍数",
                    value: "\(Int(viewModel.output.currentHeartRate))",
                    unit: "BPM",
                    icon: "heart.fill",
                    color: .red
                )
                
                DataCard(
                    title: "カロリー",
                    value: "\(Int(viewModel.output.currentCalories))",
                    unit: "kcal",
                    icon: "flame.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var strengthTrainingSection: some View {
        VStack(spacing: 15) {
            Text("筋トレセット")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack {
                    Text("セット")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.output.currentSet)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                VStack {
                    Text("レップ数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.output.currentReps)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                VStack {
                    Text("重量")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(viewModel.output.currentWeight))kg")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            
            // セット記録ボタン
            Button("セット記録") {
                viewModel.recordSet()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.output.currentReps == 0 || viewModel.output.currentWeight == 0)
            
            // レストタイマー
            if viewModel.output.restTime > 0 {
                Text("レスト: \(viewModel.timeString(from: viewModel.output.restTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var controlButtons: some View {
        HStack(spacing: 20) {
            if !viewModel.output.isWorkoutActive {
                Button("ワークアウト開始") {
                    viewModel.startWorkout()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.output.isAuthorized)
            } else {
                Button("ワークアウト停止") {
                    viewModel.stopWorkout()
                }
                .buttonStyle(.borderedProminent)
                .foregroundColor(.red)
            }
        }
    }
    
    private func updateWorkoutData() {
        guard let startTime = viewModel.output.workoutStartTime else { return }
        
        // ワークアウト時間の更新
        viewModel.output.workoutDuration = Date().timeIntervalSince(startTime)
        
        // 心拍数とカロリーの取得（実際のアプリではHealthKitから取得）
        // ここではダミーデータを使用
        viewModel.output.currentHeartRate = Double.random(in: 120...180)
        viewModel.output.currentCalories = viewModel.output.workoutDuration / 60 * 10 // 仮の計算
    }
    

}

// データカード
struct DataCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}



#Preview {
    ContentView()
}
