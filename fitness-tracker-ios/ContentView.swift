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
            
            // 栄養管理
            NutritionAnalysisView()
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("栄養")
                }
            
            // 筋トレ分析
            AdvancedAnalysisView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("分析")
                }
            

            
            // デバッグ画面
            DebugView()
                .tabItem {
                    Image(systemName: "ladybug.fill")
                    Text("デバッグ")
                }
        }
        .accentColor(.blue)
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
