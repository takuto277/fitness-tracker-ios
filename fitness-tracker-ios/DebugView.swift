import SwiftUI
import HealthKit

struct DebugView: View {
    @StateObject private var viewModel = DebugViewModel()
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    
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
                
                ScrollView {
                    VStack(spacing: 20) {
                        // ヘッダー
                        headerSection
                        
                        // 日付選択
                        dateSelectionSection
                        
                        // データサマリー
                        dataSummarySection
                        
                        // 詳細データ
                        detailedDataSection
                        
                        // 生データ
                        rawDataSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingDatePicker) {
                DatePickerView(selectedDate: $selectedDate, isPresented: $showingDatePicker)
            }
            .onAppear {
                viewModel.loadData(for: selectedDate)
            }
            .onChange(of: selectedDate) { newDate in
                viewModel.loadData(for: newDate)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("DEBUG")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("DATA VIEWER")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.cyan)
                }
                
                Spacer()
                
                // ステータスインジケーター
                Circle()
                    .fill(viewModel.isLoading ? Color.yellow : Color.green)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 20, height: 20)
                    )
            }
            
            Text("HealthKitデータの詳細表示")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 5)
    }
    
    // MARK: - Date Selection Section
    private var dateSelectionSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("日付選択")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    showingDatePicker = true
                }) {
                    HStack {
                        Image(systemName: "calendar")
                        Text(DateUtil.shared.formatJapaneseDate(selectedDate))
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.cyan.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                            )
                    )
                }
            }
            
            // クイック日付選択
            HStack(spacing: 10) {
                ForEach(["今日", "昨日", "3日前", "1週間前"], id: \.self) { label in
                    Button(action: {
                        switch label {
                        case "今日":
                            selectedDate = Date()
                        case "昨日":
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                        case "3日前":
                            selectedDate = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
                        case "1週間前":
                            selectedDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                        default:
                            break
                        }
                    }) {
                        Text(label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Data Summary Section
    private var dataSummarySection: some View {
        VStack(spacing: 15) {
            Text("データサマリー")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                DebugSummaryCard(
                    title: "筋トレ回数",
                    value: "\(viewModel.workoutCount)",
                    unit: "回",
                    icon: "dumbbell.fill",
                    color: .orange
                )
                
                DebugSummaryCard(
                    title: "総時間",
                    value: "\(Int(viewModel.totalWorkoutDuration / 60))",
                    unit: "分",
                    icon: "clock.fill",
                    color: .blue
                )
                
                DebugSummaryCard(
                    title: "消費カロリー",
                    value: "\(Int(viewModel.totalCalories))",
                    unit: "kcal",
                    icon: "flame.fill",
                    color: .red
                )
                
                DebugSummaryCard(
                    title: "平均心拍数",
                    value: "\(Int(viewModel.averageHeartRate))",
                    unit: "BPM",
                    icon: "heart.fill",
                    color: .pink
                )
            }
        }
    }
    
    // MARK: - Detailed Data Section
    private var detailedDataSection: some View {
        VStack(spacing: 15) {
            Text("詳細データ")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            // 筋トレデータ
            if !viewModel.workouts.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("筋トレセッション")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.orange)
                    
                    ForEach(viewModel.workouts, id: \.uuid) { workout in
                        WorkoutDetailCard(workout: workout)
                    }
                }
            }
            
            // 心拍数データ
            if !viewModel.heartRateData.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("心拍数データ")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                    
                    ForEach(viewModel.heartRateData.prefix(5), id: \.uuid) { sample in
                        HeartRateDetailCard(sample: sample)
                    }
                }
            }
            
            // カロリーデータ
            if !viewModel.calorieData.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("カロリーデータ")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.orange)
                    
                    ForEach(viewModel.calorieData.prefix(5), id: \.uuid) { sample in
                        CalorieDetailCard(sample: sample)
                    }
                }
            }
        }
    }
    
    // MARK: - Raw Data Section
    private var rawDataSection: some View {
        VStack(spacing: 15) {
            Text("生データ")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("取得日時: \(viewModel.lastFetchTime)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("データ件数: \(viewModel.totalDataCount)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("エラー数: \(viewModel.errorCount)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
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
}

// MARK: - Supporting Views

struct DebugSummaryCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text(unit)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
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

struct WorkoutDetailCard: View {
    let workout: HKWorkout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.orange)
                Text(workout.workoutActivityType.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text(DateUtil.shared.formatTime(workout.startDate))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("時間")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(Int(workout.duration / 60))分")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("カロリー")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(Int(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0))kcal")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("距離")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(String(format: "%.1f", (workout.totalDistance?.doubleValue(for: .meter()) ?? 0) / 1000))km")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct HeartRateDetailCard: View {
    let sample: HKQuantitySample
    
    var body: some View {
        HStack {
            Image(systemName: "heart.fill")
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(sample.quantity.doubleValue(for: HKUnit(from: "count/min")))) BPM")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Text(DateUtil.shared.formatTime(sample.startDate))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text("〜 \(DateUtil.shared.formatTime(sample.endDate))")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct CalorieDetailCard: View {
    let sample: HKQuantitySample
    
    var body: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(sample.quantity.doubleValue(for: .kilocalorie()))) kcal")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Text(DateUtil.shared.formatTime(sample.startDate))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text("〜 \(DateUtil.shared.formatTime(sample.endDate))")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
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
                    Text("日付を選択")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    DatePicker(
                        "日付選択",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .colorScheme(.dark)
                    
                    Button("確定") {
                        isPresented = false
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.cyan.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    DebugView()
} 