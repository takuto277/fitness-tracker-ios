import SwiftUI
import HealthKit

struct WorkoutView: View {
    @ObservedObject var workoutManager: WorkoutManager
    @State private var showingAddWorkout = false
    @State private var selectedExercise: Exercise?
    @State private var isWorkoutActive = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 週間統計
                    VStack(spacing: 15) {
                        Text("今週の運動")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 30) {
                            VStack {
                                Text("\(Int(workoutManager.weeklyWorkoutMinutes))")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                Text("分")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(workoutManager.workouts.count)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                Text("回")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(Int(workoutManager.workouts.reduce(0) { $0 + $1.calories }))")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                Text("kcal")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // クイックスタート
                    VStack(spacing: 15) {
                        Text("クイックスタート")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                            QuickStartCard(
                                title: "ウォーキング",
                                icon: "figure.walk",
                                color: .blue,
                                duration: "30分"
                            ) {
                                startQuickWorkout(.walking)
                            }
                            
                            QuickStartCard(
                                title: "ランニング",
                                icon: "figure.run",
                                color: .red,
                                duration: "20分"
                            ) {
                                startQuickWorkout(.running)
                            }
                            
                            QuickStartCard(
                                title: "筋力トレーニング",
                                icon: "dumbbell.fill",
                                color: .green,
                                duration: "45分"
                            ) {
                                startQuickWorkout(.functionalStrengthTraining)
                            }
                            
                            QuickStartCard(
                                title: "ヨガ",
                                icon: "figure.mind.and.body",
                                color: .purple,
                                duration: "30分"
                            ) {
                                startQuickWorkout(.yoga)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // エクササイズリスト
                    VStack(spacing: 15) {
                        Text("エクササイズ")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(workoutManager.exercises, id: \.name) { exercise in
                                ExerciseCard(exercise: exercise) {
                                    selectedExercise = exercise
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 最近のワークアウト
                    if !workoutManager.workouts.isEmpty {
                        VStack(spacing: 15) {
                            Text("最近のワークアウト")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVStack(spacing: 12) {
                                ForEach(workoutManager.workouts.prefix(5), id: \.id) { workout in
                                    WorkoutHistoryCard(workout: workout)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // 筋トレ専用セクション
                    let strengthWorkouts = workoutManager.workouts.filter { workout in
                        workout.type == .functionalStrengthTraining || 
                        workout.type == .traditionalStrengthTraining ||
                        workout.type == .coreTraining
                    }
                    
                    if !strengthWorkouts.isEmpty {
                        VStack(spacing: 15) {
                            Text("筋トレ記録")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            // 筋トレ統計
                            HStack(spacing: 20) {
                                VStack {
                                    Text("\(strengthWorkouts.count)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.purple)
                                    Text("回")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack {
                                    Text("\(Int(strengthWorkouts.reduce(0) { $0 + $1.duration } / 60))")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.purple)
                                    Text("分")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack {
                                    Text("\(Int(strengthWorkouts.reduce(0) { $0 + $1.calories }))")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.purple)
                                    Text("kcal")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // 最近の筋トレ
                            LazyVStack(spacing: 12) {
                                ForEach(strengthWorkouts.prefix(3), id: \.id) { workout in
                                    StrengthWorkoutCard(workout: workout)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("ワークアウト")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddWorkout = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddWorkout) {
                AddWorkoutView(workoutManager: workoutManager)
            }
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
            .overlay(
                // アクティブなワークアウト表示
                VStack {
                    if isWorkoutActive {
                        ActiveWorkoutView(isActive: $isWorkoutActive)
                    }
                    Spacer()
                }
            )
        }
    }
    
    private func startQuickWorkout(_ type: HKWorkoutActivityType) {
        isWorkoutActive = true
        workoutManager.startWorkout(type: type)
    }
}

struct QuickStartCard: View {
    let title: String
    let icon: String
    let color: Color
    let duration: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(duration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ExerciseCard: View {
    let exercise: Exercise
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: exercise.category.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        if exercise.sets > 0 {
                            Text("\(exercise.sets)セット")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if exercise.reps > 0 {
                            Text("\(exercise.reps)回")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let duration = exercise.duration {
                            Text("\(Int(duration/60))分")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorkoutHistoryCard: View {
    let workout: Workout
    
    var body: some View {
        HStack {
            Image(systemName: getWorkoutIcon(for: workout.type))
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(Int(workout.duration/60))分 • \(Int(workout.calories))kcal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(DateUtil.shared.formatJapaneseDateShort(workout.date))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func getWorkoutIcon(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .yoga: return "figure.mind.and.body"
        case .functionalStrengthTraining: return "dumbbell.fill"
        case .flexibility: return "figure.flexibility"
        default: return "figure.mixed.cardio"
        }
    }
}

struct ActiveWorkoutView: View {
    @Binding var isActive: Bool
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("ワークアウト中")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    stopWorkout()
                }) {
                    Image(systemName: "stop.fill")
                        .foregroundColor(.white)
                }
            }
            
            Text(timeString(from: elapsedTime))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.blue)
        .cornerRadius(12)
        .padding(.horizontal)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func stopWorkout() {
        stopTimer()
        isActive = false
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct AddWorkoutView: View {
    @ObservedObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: HKWorkoutActivityType = .walking
    @State private var duration: TimeInterval = 1800 // 30分
    @State private var calories: Double = 0
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("ワークアウト詳細") {
                    Picker("運動タイプ", selection: $selectedType) {
                        Text("ウォーキング").tag(HKWorkoutActivityType.walking)
                        Text("ランニング").tag(HKWorkoutActivityType.running)
                        Text("サイクリング").tag(HKWorkoutActivityType.cycling)
                        Text("筋力トレーニング").tag(HKWorkoutActivityType.functionalStrengthTraining)
                        Text("ヨガ").tag(HKWorkoutActivityType.yoga)
                        Text("ストレッチ").tag(HKWorkoutActivityType.flexibility)
                    }
                    
                    HStack {
                        Text("時間")
                        Spacer()
                        Text("\(Int(duration/60))分")
                    }
                    
                    Slider(value: $duration, in: 300...7200, step: 300)
                    
                    HStack {
                        Text("消費カロリー")
                        Spacer()
                        TextField("kcal", value: $calories, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("メモ") {
                    TextField("メモを入力", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("ワークアウト追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveWorkout()
                    }
                }
            }
        }
    }
    
    private func saveWorkout() {
        let workout = Workout(
            name: selectedType.name,
            type: selectedType,
            duration: duration,
            calories: calories,
            date: Date(),
            notes: notes.isEmpty ? nil : notes
        )
        
        workoutManager.workouts.append(workout)
        dismiss()
    }
}

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // エクササイズヘッダー
                    VStack(spacing: 15) {
                        Image(systemName: exercise.category.icon)
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text(exercise.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(exercise.category.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // 詳細情報
                    VStack(spacing: 15) {
                        Text("詳細")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            if exercise.sets > 0 {
                                DetailRow(title: "セット数", value: "\(exercise.sets)セット")
                            }
                            
                            if exercise.reps > 0 {
                                DetailRow(title: "回数", value: "\(exercise.reps)回")
                            }
                            
                            if let weight = exercise.weight {
                                DetailRow(title: "重量", value: "\(weight)kg")
                            }
                            
                            if let duration = exercise.duration {
                                DetailRow(title: "時間", value: "\(Int(duration/60))分")
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("エクササイズ詳細")
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

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

struct StrengthWorkoutCard: View {
    let workout: Workout
    
    var body: some View {
        HStack {
            Image(systemName: "dumbbell.fill")
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Text("\(Int(workout.duration/60))分")
                        .font(.subheadline)
                        .foregroundColor(.purple)
                        .fontWeight(.semibold)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(workout.calories))kcal")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .fontWeight(.semibold)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(DateUtil.shared.formatJapaneseDateShort(workout.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(DateUtil.shared.formatJapaneseDate(workout.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    WorkoutView(workoutManager: WorkoutManager())
} 