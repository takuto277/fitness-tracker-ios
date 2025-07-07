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
    @StateObject private var progressManager = ProgressManager()
    
    var body: some View {
        TabView {
            // 筋トレダッシュボード
            DashboardView(
                healthKitManager: healthKitManager,
                bodyCompositionManager: bodyCompositionManager,
                progressManager: progressManager
            )
            .tabItem {
                Image(systemName: "house.fill")
                Text("ダッシュボード")
            }
            
            // 筋トレセッション
            RealTimeWorkoutView(healthKitManager: healthKitManager)
                .tabItem {
                    Image(systemName: "dumbbell.fill")
                    Text("筋トレ")
                }
            
            // 体組成管理
            BodyCompositionView(bodyCompositionManager: bodyCompositionManager)
                .tabItem {
                    Image(systemName: "scalemass.fill")
                    Text("体組成")
                }
            
            // フィットネス分析
            FitnessAnalysisView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("分析")
                }
            
            // More（音声ガイド・デバッグ）
            MoreView()
                .tabItem {
                    Image(systemName: "ellipsis.circle.fill")
                    Text("More")
                }
        }
        .accentColor(.blue)
    }
}

// 音声ガイド選択画面
struct VoiceGuideSelectionView: View {
    @State private var selectedExercise: ExerciseType?
    @State private var showingExerciseSetup = false
    
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
                
                VStack(spacing: 30) {
                    // ヘッダー
                    headerSection
                    
                    // エクササイズ選択
                    exerciseSelectionSection
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingExerciseSetup) {
                if let exercise = selectedExercise {
                    ExerciseSetupView(
                        exercise: exercise,
                        isPresented: $showingExerciseSetup,
                        onStart: { exerciseType, sets, reps, weight in
                            // 音声ガイド付き筋トレを開始
                            print("音声ガイド付き筋トレ開始: \(exerciseType.displayName)")
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("VOICE")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("GUIDE")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.cyan)
                }
                
                Spacer()
            }
            
            Text("音声でガイドする筋トレ")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 5)
    }
    
    // MARK: - Exercise Selection Section
    private var exerciseSelectionSection: some View {
        VStack(spacing: 20) {
            Text("エクササイズを選択")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2), spacing: 20) {
                ForEach(ExerciseType.allCases, id: \.self) { exercise in
                    ExerciseCard(exercise: exercise) {
                        selectedExercise = exercise
                        showingExerciseSetup = true
                    }
                }
            }
        }
    }
}

// エクササイズカード
struct ExerciseCard: View {
    let exercise: ExerciseType
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [.cyan.opacity(0.8), .blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: exercise.icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(exercise.displayName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
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
        .buttonStyle(PlainButtonStyle())
    }
}

// More画面
struct MoreView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("音声ガイド")) {
                    NavigationLink(destination: VoiceGuideSelectionView()) {
                        HStack {
                            Image(systemName: "speaker.wave.3.fill")
                                .foregroundColor(.cyan)
                                .frame(width: 30)
                            Text("音声ガイド")
                        }
                    }
                }
                
                Section(header: Text("開発・デバッグ")) {
                    NavigationLink(destination: DebugView()) {
                        HStack {
                            Image(systemName: "ladybug.fill")
                                .foregroundColor(.orange)
                                .frame(width: 30)
                            Text("デバッグ")
                        }
                    }
                }
            }
            .navigationTitle("More")
        }
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
