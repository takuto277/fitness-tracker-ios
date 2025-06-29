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
    @StateObject private var nutritionManager = NutritionManager()
    @StateObject private var progressManager = ProgressManager()
    
    var body: some View {
        TabView {
            // 統合ダッシュボード
            DashboardView()
                .environmentObject(healthKitManager)
                .environmentObject(bodyCompositionManager)
                .environmentObject(progressManager)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ダッシュボード")
                }
            
            // リアルタイム運動
            RealTimeWorkoutView()
                .environmentObject(healthKitManager)
                .tabItem {
                    Image(systemName: "figure.run")
                    Text("リアルタイム運動")
                }
            
            // 体組成管理
            BodyCompositionView()
                .environmentObject(bodyCompositionManager)
                .tabItem {
                    Image(systemName: "scalemass.fill")
                    Text("体組成")
                }
            
            // 栄養分析
            NutritionAnalysisView()
                .environmentObject(nutritionManager)
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("栄養分析")
                }
            
            // 進捗分析
            ProgressAnalysisView()
                .environmentObject(progressManager)
                .environmentObject(healthKitManager)
                .environmentObject(bodyCompositionManager)
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
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var selectedWorkoutType: HKWorkoutActivityType = .traditionalStrengthTraining
    @State private var isWorkoutActive = false
    @State private var workoutStartTime: Date?
    @State private var currentHeartRate: Double = 0
    @State private var currentCalories: Double = 0
    @State private var workoutDuration: TimeInterval = 0
    
    // 筋トレ専用データ
    @State private var currentSet: Int = 0
    @State private var currentReps: Int = 0
    @State private var currentWeight: Double = 0
    @State private var restTime: TimeInterval = 0
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // ワークアウトタイプ選択
                    if !isWorkoutActive {
                        workoutTypeSelector
                    }
                    
                    // リアルタイムデータ表示
                    if isWorkoutActive {
                        realTimeDataView
                        
                        // 筋トレ専用セクション
                        if selectedWorkoutType == .traditionalStrengthTraining {
                            strengthTrainingSection
                        }
                    }
                    
                    // コントロールボタン
                    controlButtons
                }
                .padding()
            }
            .navigationTitle("リアルタイム運動")
            .onReceive(timer) { _ in
                if isWorkoutActive {
                    updateWorkoutData()
                }
            }
        }
    }
    
    private var workoutTypeSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ワークアウトタイプ")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                ForEach(availableWorkoutTypes, id: \.self) { type in
                    Button(action: {
                        selectedWorkoutType = type
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
                                .fill(selectedWorkoutType == type ? type.color.opacity(0.2) : Color.gray.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedWorkoutType == type ? type.color : Color.clear, lineWidth: 2)
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
            Text(timeString(from: workoutDuration))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.blue)
            
            // リアルタイムデータ
            HStack(spacing: 20) {
                DataCard(
                    title: "心拍数",
                    value: "\(Int(currentHeartRate))",
                    unit: "BPM",
                    icon: "heart.fill",
                    color: .red
                )
                
                DataCard(
                    title: "カロリー",
                    value: "\(Int(currentCalories))",
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
                    Text("\(currentSet)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                VStack {
                    Text("レップ数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(currentReps)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                VStack {
                    Text("重量")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(currentWeight))kg")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            
            // セット記録ボタン
            Button("セット記録") {
                recordSet()
            }
            .buttonStyle(.borderedProminent)
            .disabled(currentReps == 0 || currentWeight == 0)
            
            // レストタイマー
            if restTime > 0 {
                Text("レスト: \(timeString(from: restTime))")
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
            if !isWorkoutActive {
                Button("ワークアウト開始") {
                    startWorkout()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!healthKitManager.isAuthorized)
            } else {
                Button("ワークアウト停止") {
                    stopWorkout()
                }
                .buttonStyle(.borderedProminent)
                .foregroundColor(.red)
            }
        }
    }
    
    private func startWorkout() {
        isWorkoutActive = true
        workoutStartTime = Date()
        currentSet = 1
        currentReps = 0
        currentWeight = 0
        restTime = 0
        
        // HealthKitにワークアウト開始を記録
        healthKitManager.startWorkout(type: selectedWorkoutType)
    }
    
    private func stopWorkout() {
        isWorkoutActive = false
        workoutStartTime = nil
        
        // HealthKitにワークアウト終了を記録
        healthKitManager.endWorkout()
    }
    
    private func recordSet() {
        // セット記録
        currentSet += 1
        currentReps = 0
        currentWeight = 0
        startRestTimer()
    }
    
    private func startRestTimer() {
        restTime = 0
        // レストタイマーは既にメインタイマーで処理されている
    }
    
    private func updateWorkoutData() {
        guard let startTime = workoutStartTime else { return }
        
        // ワークアウト時間の更新
        workoutDuration = Date().timeIntervalSince(startTime)
        
        // 心拍数とカロリーの取得（実際のアプリではHealthKitから取得）
        // ここではダミーデータを使用
        currentHeartRate = Double.random(in: 120...180)
        currentCalories = workoutDuration / 60 * 10 // 仮の計算
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private var availableWorkoutTypes: [HKWorkoutActivityType] {
        [
            .traditionalStrengthTraining,
            .functionalStrengthTraining,
            .coreTraining,
            .running,
            .walking,
            .cycling,
            .swimming,
            .yoga,
            .pilates,
            .mixedCardio
        ]
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

// HKWorkoutActivityType拡張
extension HKWorkoutActivityType {
    var displayName: String {
        switch self {
        case .traditionalStrengthTraining:
            return "筋トレ"
        case .functionalStrengthTraining:
            return "機能的な筋トレ"
        case .coreTraining:
            return "コアトレーニング"
        case .running:
            return "ランニング"
        case .walking:
            return "ウォーキング"
        case .cycling:
            return "サイクリング"
        case .swimming:
            return "水泳"
        case .yoga:
            return "ヨガ"
        case .pilates:
            return "ピラティス"
        case .mixedCardio:
            return "混合有酸素運動"
        default:
            return "その他"
        }
    }
    
    var icon: String {
        switch self {
        case .traditionalStrengthTraining, .functionalStrengthTraining:
            return "dumbbell.fill"
        case .coreTraining:
            return "figure.core.training"
        case .running:
            return "figure.run"
        case .walking:
            return "figure.walk"
        case .cycling:
            return "bicycle"
        case .swimming:
            return "figure.pool.swim"
        case .yoga:
            return "figure.mind.and.body"
        case .pilates:
            return "figure.pilates"
        case .mixedCardio:
            return "figure.mixed.cardio"
        default:
            return "figure.mixed.cardio"
        }
    }
    
    var color: Color {
        switch self {
        case .traditionalStrengthTraining, .functionalStrengthTraining, .coreTraining:
            return .orange
        case .running, .walking, .cycling, .swimming, .mixedCardio:
            return .blue
        case .yoga, .pilates:
            return .green
        default:
            return .gray
        }
    }
}

#Preview {
    ContentView()
}
