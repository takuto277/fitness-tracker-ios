import SwiftUI

struct SettingsView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("userAge") private var userAge = ""
    @AppStorage("userWeight") private var userWeight = ""
    @AppStorage("userHeight") private var userHeight = ""
    @AppStorage("dailyCalorieGoal") private var dailyCalorieGoal = 2000.0
    @AppStorage("dailyProteinGoal") private var dailyProteinGoal = 80.0
    @AppStorage("dailyWaterGoal") private var dailyWaterGoal = 2000.0
    @AppStorage("dailyStepGoal") private var dailyStepGoal = 10000.0
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("reminderTime") private var reminderTime = Date()
    
    @State private var showingHealthKitSettings = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            Form {
                // プロフィール設定
                Section("プロフィール") {
                    HStack {
                        Text("名前")
                        Spacer()
                        TextField("名前を入力", text: $userName)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("年齢")
                        Spacer()
                        TextField("年齢", text: $userAge)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("体重")
                        Spacer()
                        TextField("kg", text: $userWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("身長")
                        Spacer()
                        TextField("cm", text: $userHeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // 目標設定
                Section("目標設定") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("1日のカロリー目標")
                            Spacer()
                            Text("\(Int(dailyCalorieGoal)) kcal")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $dailyCalorieGoal, in: 1200...3000, step: 50)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("1日のタンパク質目標")
                            Spacer()
                            Text("\(Int(dailyProteinGoal)) g")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $dailyProteinGoal, in: 50...150, step: 5)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("1日の水分摂取目標")
                            Spacer()
                            Text("\(Int(dailyWaterGoal)) ml")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $dailyWaterGoal, in: 1000...4000, step: 100)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("1日の歩数目標")
                            Spacer()
                            Text("\(Int(dailyStepGoal)) 歩")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $dailyStepGoal, in: 5000...20000, step: 500)
                    }
                }
                
                // 通知設定
                Section("通知設定") {
                    Toggle("通知を有効にする", isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        DatePicker("リマインダー時間", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("通知内容")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            NotificationOptionRow(title: "運動リマインダー", isEnabled: true)
                            NotificationOptionRow(title: "水分摂取リマインダー", isEnabled: true)
                            NotificationOptionRow(title: "目標達成通知", isEnabled: true)
                            NotificationOptionRow(title: "週間レポート", isEnabled: false)
                        }
                    }
                }
                
                // データ管理
                Section("データ管理") {
                    Button(action: {
                        showingHealthKitSettings = true
                    }) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("HealthKit設定")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        // データエクスポート機能
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("データをエクスポート")
                            Spacer()
                        }
                    }
                    
                    Button(action: {
                        // データリセット機能
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("データをリセット")
                            Spacer()
                        }
                    }
                }
                
                // アプリ情報
                Section("アプリ情報") {
                    Button(action: {
                        showingAbout = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("アプリについて")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        HStack {
                            Image(systemName: "hand.raised")
                                .foregroundColor(.blue)
                            Text("プライバシーポリシー")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            Text("利用規約")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("設定")
            .sheet(isPresented: $showingHealthKitSettings) {
                HealthKitSettingsView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
}

struct NotificationOptionRow: View {
    let title: String
    let isEnabled: Bool
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if isEnabled {
                Image(systemName: "checkmark")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "xmark")
                    .foregroundColor(.red)
            }
        }
        .font(.subheadline)
    }
}

struct HealthKitSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("HealthKit設定")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("HealthKitの権限設定は、iPhoneの「設定」アプリから行うことができます。")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 15) {
                    Text("設定手順:")
                        .font(.headline)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        StepRow(number: "1", text: "iPhoneの「設定」アプリを開く")
                        StepRow(number: "2", text: "「プライバシーとセキュリティ」をタップ")
                        StepRow(number: "3", text: "「Health」をタップ")
                        StepRow(number: "4", text: "アプリ名をタップして権限を設定")
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                Button("設定アプリを開く") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                .foregroundColor(.blue)
                .padding()
            }
            .padding()
            .navigationTitle("HealthKit設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StepRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Text(number)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 25, height: 25)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("HealthKit Fit Journey")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("2ヶ月で健康的なライフスタイルを確立するためのアプリです。")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 15) {
                        Text("主な機能")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            FeatureRow(icon: "target", title: "目標設定・管理", description: "6つの主要目標を設定し、進捗を追跡")
                            FeatureRow(icon: "dumbbell.fill", title: "ワークアウト記録", description: "運動の記録と管理")
                            FeatureRow(icon: "fork.knife", title: "栄養管理", description: "食事と栄養素の記録")
                            FeatureRow(icon: "chart.bar.fill", title: "データ分析", description: "HealthKitと連携した健康データの可視化")
                        }
                        .padding(.horizontal)
                    }
                    
                    VStack(spacing: 10) {
                        Text("開発者")
                            .font(.headline)
                        
                        Text("小野拓人")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("アプリについて")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
} 