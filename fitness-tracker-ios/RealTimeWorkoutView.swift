import SwiftUI
import HealthKit

struct RealTimeWorkoutView: View {
    @StateObject private var viewModel: RealTimeWorkoutViewModel
    @State private var showingWorkoutPicker = false
    @State private var selectedWorkoutType: HKWorkoutActivityType = .traditionalStrengthTraining
    
    init(healthKitManager: HealthKitManager) {
        self._viewModel = StateObject(wrappedValue: RealTimeWorkoutViewModel(healthKitManager: healthKitManager))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.2, green: 0.1, blue: 0.3),
                        Color(red: 0.1, green: 0.05, blue: 0.15)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // ヘッダーセクション
                        headerSection
                        
                        // メインタイマーセクション
                        mainTimerSection
                        
                        // 統計カード
                        statsSection
                        
                        // コントロールボタン
                        controlSection
                        
                        // 最近のワークアウト
                        recentWorkoutsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingWorkoutPicker) {
                WorkoutTypePickerView(selectedType: $selectedWorkoutType, isPresented: $showingWorkoutPicker)
            }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                viewModel.updateWorkoutData()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("STRENGTH")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("TRAINING")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                // ステータスインジケーター
                Circle()
                    .fill(viewModel.output.isWorkoutActive ? Color.green : Color.gray)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 20, height: 20)
                    )
            }
            
            Text("今日の筋トレセッション")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 5)
    }
    
    // MARK: - Main Timer Section
    private var mainTimerSection: some View {
        VStack(spacing: 20) {
            // 大きなタイマー
            ZStack {
                // 背景円
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 280, height: 280)
                
                // プログレス円
                Circle()
                    .trim(from: 0, to: viewModel.output.progress)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .red]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: viewModel.output.progress)
                
                // タイマー表示
                VStack(spacing: 8) {
                    Text(viewModel.output.formattedTime)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.5)
                    
                    Text(viewModel.output.isWorkoutActive ? "トレーニング中" : "準備完了")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // セット情報
            if viewModel.output.isWorkoutActive {
                HStack(spacing: 30) {
                    VStack(spacing: 5) {
                        Text("\(viewModel.output.currentSet)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.orange)
                        Text("セット")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    VStack(spacing: 5) {
                        Text("\(viewModel.output.totalSets)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Text("目標")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    VStack(spacing: 5) {
                        Text("\(viewModel.output.restTimeRemaining)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.green)
                        Text("休憩")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 2), spacing: 15) {
            StatCard(
                title: "心拍数",
                value: "\(Int(viewModel.output.heartRate))",
                unit: "BPM",
                icon: "heart.fill",
                color: .red,
                gradient: LinearGradient(colors: [.red.opacity(0.8), .pink.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            
            StatCard(
                title: "消費カロリー",
                value: "\(Int(viewModel.output.caloriesBurned))",
                unit: "kcal",
                icon: "flame.fill",
                color: .orange,
                gradient: LinearGradient(colors: [.orange.opacity(0.8), .yellow.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            
            StatCard(
                title: "平均重量",
                value: "\(Int(viewModel.output.averageWeight))",
                unit: "kg",
                icon: "dumbbell.fill",
                color: .blue,
                gradient: LinearGradient(colors: [.blue.opacity(0.8), .cyan.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            
            StatCard(
                title: "総重量",
                value: "\(Int(viewModel.output.totalWeight))",
                unit: "kg",
                icon: "scalemass.fill",
                color: .purple,
                gradient: LinearGradient(colors: [.purple.opacity(0.8), .indigo.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        }
    }
    
    // MARK: - Control Section
    private var controlSection: some View {
        VStack(spacing: 20) {
            if viewModel.output.isWorkoutActive {
                // ワークアウト中のコントロール
                HStack(spacing: 20) {
                    Button(action: viewModel.pauseWorkout) {
                        HStack {
                            Image(systemName: viewModel.output.isPaused ? "play.fill" : "pause.fill")
                            Text(viewModel.output.isPaused ? "再開" : "一時停止")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(colors: [.blue.opacity(0.8), .cyan.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .cornerRadius(15)
                    }
                    
                    Button(action: viewModel.endWorkout) {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("終了")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(colors: [.red.opacity(0.8), .pink.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .cornerRadius(15)
                    }
                }
            } else {
                // ワークアウト開始ボタン
                Button(action: {
                    showingWorkoutPicker = true
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("筋トレ開始")
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        LinearGradient(colors: [.orange.opacity(0.8), .red.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .cornerRadius(20)
                    .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                }
            }
        }
    }
    
    // MARK: - Recent Workouts Section
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("最近のワークアウト")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            ForEach(viewModel.output.recentWorkouts, id: \.uuid) { workout in
                RecentWorkoutCard(workout: workout)
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let gradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(unit)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct RecentWorkoutCard: View {
    let workout: HKWorkout
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.orange.opacity(0.8), .red.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.workoutActivityType.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(DateUtil.shared.formatJapaneseDate(workout.startDate))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("\(Int(workout.duration / 60))分 • \(Int(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0))kcal")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(workout.duration / 60))")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.orange)
                
                Text("分")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct WorkoutTypePickerView: View {
    @Binding var selectedType: HKWorkoutActivityType
    @Binding var isPresented: Bool
    @StateObject private var viewModel = RealTimeWorkoutViewModel(healthKitManager: HealthKitManager())
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.2, green: 0.1, blue: 0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Text("ワークアウトタイプを選択")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2), spacing: 20) {
                        ForEach(RealTimeWorkoutViewModel.availableWorkoutTypes, id: \.self) { type in
                            WorkoutTypeCard(
                                type: type,
                                isSelected: selectedType == type,
                                action: {
                                    selectedType = type
                                    viewModel.startWorkout(type: type)
                                    isPresented = false
                                }
                            )
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
}

struct WorkoutTypeCard: View {
    let type: HKWorkoutActivityType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(colors: [.orange.opacity(0.8), .red.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: type.icon)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                }
                
                Text(type.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(isSelected ? 0.2 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? Color.orange.opacity(0.5) : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    RealTimeWorkoutView(healthKitManager: HealthKitManager())
} 