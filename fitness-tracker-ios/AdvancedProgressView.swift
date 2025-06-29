import SwiftUI
import HealthKit

struct AdvancedProgressView: View {
    @ObservedObject var progressTracker: ProgressTracker
    @State private var selectedMetric: ProgressMetric = .weight
    @State private var showingGoalSetting = false
    
    enum ProgressMetric: String, CaseIterable {
        case weight = "体重"
        case muscle = "筋肉量"
        case bodyFat = "体脂肪率"
        case bmi = "BMI"
        case vo2max = "VO2Max"
        case sleep = "睡眠"
        case nutrition = "栄養"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // メトリクス選択
                    Picker("メトリクス", selection: $selectedMetric) {
                        ForEach(ProgressMetric.allCases, id: \.self) { metric in
                            Text(metric.rawValue).tag(metric)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // 選択されたメトリクスの詳細表示
                    switch selectedMetric {
                    case .weight:
                        WeightProgressView(progressTracker: progressTracker)
                    case .muscle:
                        MuscleProgressView(progressTracker: progressTracker)
                    case .bodyFat:
                        BodyFatProgressView(progressTracker: progressTracker)
                    case .bmi:
                        BMIProgressView(progressTracker: progressTracker)
                    case .vo2max:
                        VO2MaxProgressView(progressTracker: progressTracker)
                    case .sleep:
                        SleepProgressView(progressTracker: progressTracker)
                    case .nutrition:
                        NutritionProgressView(progressTracker: progressTracker)
                    }
                    
                    // 目標設定ボタン
                    Button(action: {
                        showingGoalSetting = true
                    }) {
                        HStack {
                            Image(systemName: "target")
                            Text("目標を設定")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("詳細進捗")
            .sheet(isPresented: $showingGoalSetting) {
                GoalSettingView(progressTracker: progressTracker)
            }
        }
    }
}

struct WeightProgressView: View {
    @ObservedObject var progressTracker: ProgressTracker
    
    var body: some View {
        VStack(spacing: 15) {
            Text("体重管理進捗")
                .font(.headline)
            
            if let currentWeight = progressTracker.progressData.last?.weight,
               let initialWeight = progressTracker.progressData.first?.weight {
                let change = currentWeight - initialWeight
                let percentage = (change / initialWeight) * 100
                
                VStack(spacing: 10) {
                    HStack {
                        Text("現在の体重:")
                        Spacer()
                        Text("\(String(format: "%.1f", currentWeight))kg")
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("変化量:")
                        Spacer()
                        Text("\(String(format: "%.1f", change))kg (\(String(format: "%.1f", percentage))%)")
                            .fontWeight(.bold)
                            .foregroundColor(change < 0 ? .green : .red)
                    }
                    
                    ProgressView(value: progressTracker.getWeightProgress())
                        .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
    }
}

struct MuscleProgressView: View {
    @ObservedObject var progressTracker: ProgressTracker
    
    var body: some View {
        VStack(spacing: 15) {
            Text("筋肉量進捗")
                .font(.headline)
            
            if let currentMuscle = progressTracker.progressData.last?.muscleMass,
               let initialMuscle = progressTracker.progressData.first?.muscleMass {
                let change = currentMuscle - initialMuscle
                let percentage = (change / initialMuscle) * 100
                
                VStack(spacing: 10) {
                    HStack {
                        Text("現在の筋肉量:")
                        Spacer()
                        Text("\(String(format: "%.1f", currentMuscle))kg")
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("変化量:")
                        Spacer()
                        Text("\(String(format: "%.1f", change))kg (\(String(format: "%.1f", percentage))%)")
                            .fontWeight(.bold)
                            .foregroundColor(change > 0 ? .green : .red)
                    }
                    
                    ProgressView(value: progressTracker.getMuscleGainProgress())
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
    }
}

struct BodyFatProgressView: View {
    @ObservedObject var progressTracker: ProgressTracker
    
    var body: some View {
        VStack(spacing: 15) {
            Text("体脂肪率進捗")
                .font(.headline)
            
            if let currentBodyFat = progressTracker.progressData.last?.bodyFatPercentage,
               let initialBodyFat = progressTracker.progressData.first?.bodyFatPercentage {
                let change = currentBodyFat - initialBodyFat
                
                VStack(spacing: 10) {
                    HStack {
                        Text("現在の体脂肪率:")
                        Spacer()
                        Text("\(String(format: "%.1f", currentBodyFat))%")
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("変化量:")
                        Spacer()
                        Text("\(String(format: "%.1f", change))%")
                            .fontWeight(.bold)
                            .foregroundColor(change < 0 ? .green : .red)
                    }
                    
                    // 体脂肪率の健康レベル表示
                    BodyFatHealthLevel(bodyFat: currentBodyFat)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
    }
}

struct BodyFatHealthLevel: View {
    let bodyFat: Double
    
    var healthLevel: String {
        switch bodyFat {
        case 0..<10:
            return "低すぎる"
        case 10..<15:
            return "低い"
        case 15..<20:
            return "適正"
        case 20..<25:
            return "やや高い"
        case 25..<30:
            return "高い"
        default:
            return "非常に高い"
        }
    }
    
    var color: Color {
        switch bodyFat {
        case 0..<10, 25...:
            return .red
        case 10..<15, 20..<25:
            return .orange
        default:
            return .green
        }
    }
    
    var body: some View {
        HStack {
            Text("健康レベル:")
            Spacer()
            Text(healthLevel)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

struct BMIProgressView: View {
    @ObservedObject var progressTracker: ProgressTracker
    
    var body: some View {
        VStack(spacing: 15) {
            Text("BMI進捗")
                .font(.headline)
            
            if let currentBMI = progressTracker.progressData.last?.bodyMassIndex {
                VStack(spacing: 10) {
                    HStack {
                        Text("現在のBMI:")
                        Spacer()
                        Text("\(String(format: "%.1f", currentBMI))")
                            .fontWeight(.bold)
                    }
                    
                    BMIHealthLevel(bmi: currentBMI)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
    }
}

struct BMIHealthLevel: View {
    let bmi: Double
    
    var healthLevel: String {
        switch bmi {
        case 0..<18.5:
            return "低体重"
        case 18.5..<25:
            return "標準体重"
        case 25..<30:
            return "過体重"
        default:
            return "肥満"
        }
    }
    
    var color: Color {
        switch bmi {
        case 0..<18.5, 30...:
            return .orange
        default:
            return .green
        }
    }
    
    var body: some View {
        HStack {
            Text("健康レベル:")
            Spacer()
            Text(healthLevel)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

struct VO2MaxProgressView: View {
    @ObservedObject var progressTracker: ProgressTracker
    
    var body: some View {
        VStack(spacing: 15) {
            Text("VO2Max進捗")
                .font(.headline)
            
            Text("VO2Max（最大酸素摂取量）は心肺機能の指標です")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 10) {
                HStack {
                    Text("現在のVO2Max:")
                    Spacer()
                    Text("測定中...")
                        .foregroundColor(.secondary)
                }
                
                Text("定期的な有酸素運動で改善できます")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
}

struct SleepProgressView: View {
    @ObservedObject var progressTracker: ProgressTracker
    
    var body: some View {
        VStack(spacing: 15) {
            Text("睡眠進捗")
                .font(.headline)
            
            Text("睡眠は筋肉の回復と成長に重要です")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 10) {
                HStack {
                    Text("推奨睡眠時間:")
                    Spacer()
                    Text("7-9時間")
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("現在の睡眠:")
                    Spacer()
                    Text("測定中...")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.indigo.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
}

struct NutritionProgressView: View {
    @ObservedObject var progressTracker: ProgressTracker
    
    var body: some View {
        VStack(spacing: 15) {
            Text("栄養進捗")
                .font(.headline)
            
            VStack(spacing: 10) {
                NutritionRow(
                    title: "タンパク質",
                    description: "筋肉合成に重要",
                    target: "体重1kgあたり1.6-2.2g",
                    current: "測定中..."
                )
                
                NutritionRow(
                    title: "炭水化物",
                    description: "エネルギー源",
                    target: "総カロリーの45-65%",
                    current: "測定中..."
                )
                
                NutritionRow(
                    title: "脂質",
                    description: "ホルモン合成",
                    target: "総カロリーの20-35%",
                    current: "測定中..."
                )
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
}

struct NutritionRow: View {
    let title: String
    let description: String
    let target: String
    let current: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .fontWeight(.semibold)
                Spacer()
                Text(current)
                    .foregroundColor(.secondary)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("目標: \(target)")
                .font(.caption)
                .foregroundColor(.blue)
        }
    }
}

struct GoalSettingView: View {
    @ObservedObject var progressTracker: ProgressTracker
    @Environment(\.presentationMode) var presentationMode
    
    @State private var targetWeight: String = ""
    @State private var targetBodyFat: String = ""
    @State private var targetMuscle: String = ""
    @State private var weeklyWorkoutGoal: String = ""
    @State private var weeklyStrengthGoal: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("体重目標")) {
                    HStack {
                        Text("目標体重")
                        Spacer()
                        TextField("kg", text: $targetWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("体組成目標")) {
                    HStack {
                        Text("目標体脂肪率")
                        Spacer()
                        TextField("%", text: $targetBodyFat)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("目標筋肉量")
                        Spacer()
                        TextField("kg", text: $targetMuscle)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("運動目標")) {
                    HStack {
                        Text("週間運動時間")
                        Spacer()
                        TextField("分", text: $weeklyWorkoutGoal)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("週間筋トレ時間")
                        Spacer()
                        TextField("分", text: $weeklyStrengthGoal)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("目標設定")
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    saveGoals()
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                loadCurrentGoals()
            }
        }
    }
    
    private func loadCurrentGoals() {
        targetWeight = String(format: "%.1f", progressTracker.targetWeight)
        targetBodyFat = String(format: "%.1f", progressTracker.targetBodyFatPercentage)
        targetMuscle = String(format: "%.1f", progressTracker.targetMuscleMass)
        weeklyWorkoutGoal = String(format: "%.0f", progressTracker.weeklyWorkoutGoal)
        weeklyStrengthGoal = String(format: "%.0f", progressTracker.weeklyStrengthGoal)
    }
    
    private func saveGoals() {
        progressTracker.targetWeight = Double(targetWeight) ?? 0
        progressTracker.targetBodyFatPercentage = Double(targetBodyFat) ?? 0
        progressTracker.targetMuscleMass = Double(targetMuscle) ?? 0
        progressTracker.weeklyWorkoutGoal = Double(weeklyWorkoutGoal) ?? 150
        progressTracker.weeklyStrengthGoal = Double(weeklyStrengthGoal) ?? 90
    }
}

#Preview {
    AdvancedProgressView(progressTracker: ProgressTracker())
} 