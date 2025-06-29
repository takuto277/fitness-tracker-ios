import SwiftUI

struct GoalsView: View {
    @ObservedObject var goalManager: GoalManager
    @State private var showingAddGoal = false
    @State private var selectedGoal: Goal?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 全体進捗サマリー
                    VStack(spacing: 15) {
                        Text("全体進捗")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                                .frame(width: 120, height: 120)
                            
                            Circle()
                                .trim(from: 0, to: goalManager.getOverallProgress())
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 1.0), value: goalManager.getOverallProgress())
                            
                            VStack {
                                Text("\(Int(goalManager.getOverallProgress() * 100))%")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("完了")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("\(goalManager.getCompletedGoals().count)/\(goalManager.goals.count) 目標達成")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // 目標リスト
                    LazyVStack(spacing: 15) {
                        ForEach(goalManager.goals, id: \.id) { goal in
                            GoalCard(goal: goal) {
                                selectedGoal = goal
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("目標管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddGoal = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                AddGoalView(goalManager: goalManager)
            }
            .sheet(item: $selectedGoal) { goal in
                GoalDetailView(goal: goal, goalManager: goalManager)
            }
        }
    }
}

struct GoalCard: View {
    let goal: Goal
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: goal.type.icon)
                        .font(.title2)
                        .foregroundColor(goal.type.color)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("期限: \(DateUtil.shared.formatJapaneseDate(goal.deadline))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if goal.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(String(format: "%.1f", goal.currentValue)) / \(String(format: "%.1f", goal.targetValue)) \(goal.unit)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(goal.progressPercentage)%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(goal.type.color)
                    }
                    
                    ProgressView(value: goal.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: goal.type.color))
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddGoalView: View {
    @ObservedObject var goalManager: GoalManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var selectedType: GoalType = .steps
    @State private var targetValue = ""
    @State private var deadline = Date().addingTimeInterval(60*60*24*60) // 2ヶ月後
    
    var body: some View {
        NavigationView {
            Form {
                Section("目標の詳細") {
                    TextField("目標タイトル", text: $title)
                    
                    Picker("目標タイプ", selection: $selectedType) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    
                    TextField("目標値", text: $targetValue)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("期限", selection: $deadline, displayedComponents: .date)
                }
                
                Section("プレビュー") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title.isEmpty ? "目標タイトル" : title)
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: selectedType.icon)
                                .foregroundColor(selectedType.color)
                            Text(selectedType.rawValue)
                                .foregroundColor(.secondary)
                        }
                        
                        if let value = Double(targetValue) {
                            Text("目標: \(String(format: "%.1f", value)) \(getUnit(for: selectedType))")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("新しい目標")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        addGoal()
                    }
                    .disabled(title.isEmpty || targetValue.isEmpty)
                }
            }
        }
    }
    
    private func getUnit(for type: GoalType) -> String {
        switch type {
        case .weight: return "kg"
        case .steps: return "歩"
        case .calories: return "kcal"
        case .exercise: return "分"
        case .water: return "ml"
        case .sleep: return "時間"
        }
    }
    
    private func addGoal() {
        guard let value = Double(targetValue) else { return }
        
        let newGoal = Goal(
            title: title,
            targetValue: value,
            currentValue: 0.0,
            unit: getUnit(for: selectedType),
            type: selectedType,
            deadline: deadline,
            isCompleted: false
        )
        
        goalManager.goals.append(newGoal)
        dismiss()
    }
}

struct GoalDetailView: View {
    let goal: Goal
    @ObservedObject var goalManager: GoalManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 目標ヘッダー
                    VStack(spacing: 15) {
                        Image(systemName: goal.type.icon)
                            .font(.system(size: 60))
                            .foregroundColor(goal.type.color)
                        
                        Text(goal.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("期限: \(DateUtil.shared.formatJapaneseDate(goal.deadline))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // 進捗詳細
                    VStack(spacing: 15) {
                        Text("進捗状況")
                            .font(.headline)
                        
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                                .frame(width: 150, height: 150)
                            
                            Circle()
                                .trim(from: 0, to: goal.progress)
                                .stroke(goal.type.color, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                                .frame(width: 150, height: 150)
                                .rotationEffect(.degrees(-90))
                            
                            VStack {
                                Text("\(goal.progressPercentage)%")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("完了")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        VStack(spacing: 8) {
                            Text("\(String(format: "%.1f", goal.currentValue)) / \(String(format: "%.1f", goal.targetValue)) \(goal.unit)")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("残り: \(String(format: "%.1f", goal.targetValue - goal.currentValue)) \(goal.unit)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // 目標達成状況
                    if goal.isCompleted {
                        VStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                            
                            Text("目標達成！")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            
                            Text("おめでとうございます！この目標を達成しました。")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("目標詳細")
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

#Preview {
    GoalsView(goalManager: GoalManager())
} 
