import Foundation
import HealthKit
import SwiftUI

struct Workout {
    let id = UUID()
    let name: String
    let type: HKWorkoutActivityType
    let duration: TimeInterval
    let calories: Double
    let date: Date
    let notes: String?
}

struct Exercise: Identifiable {
    let id = UUID()
    let name: String
    let sets: Int
    let reps: Int
    let weight: Double?
    let duration: TimeInterval?
    let category: ExerciseCategory
}

enum ExerciseCategory: String, CaseIterable {
    case strength = "筋力トレーニング"
    case cardio = "有酸素運動"
    case flexibility = "ストレッチ"
    case balance = "バランス"
    
    var icon: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .cardio: return "heart.circle.fill"
        case .flexibility: return "figure.flexibility"
        case .balance: return "figure.mind.and.body"
        }
    }
}

class WorkoutManager: ObservableObject {
    let healthStore = HKHealthStore()
    @Published var workouts: [Workout] = []
    @Published var exercises: [Exercise] = []
    @Published var weeklyWorkoutMinutes: Double = 0
    @Published var monthlyWorkoutMinutes: Double = 0
    
    init() {
        setupDefaultExercises()
        requestWorkoutAuthorization()
    }
    
    private func setupDefaultExercises() {
        exercises = [
            // 筋力トレーニング
            Exercise(name: "スクワット", sets: 3, reps: 15, weight: nil, duration: nil, category: .strength),
            Exercise(name: "プッシュアップ", sets: 3, reps: 10, weight: nil, duration: nil, category: .strength),
            Exercise(name: "プランク", sets: 3, reps: 0, weight: nil, duration: 60, category: .strength),
            Exercise(name: "ランジ", sets: 3, reps: 12, weight: nil, duration: nil, category: .strength),
            
            // 有酸素運動
            Exercise(name: "ウォーキング", sets: 1, reps: 0, weight: nil, duration: 1800, category: .cardio),
            Exercise(name: "ジョギング", sets: 1, reps: 0, weight: nil, duration: 1200, category: .cardio),
            Exercise(name: "サイクリング", sets: 1, reps: 0, weight: nil, duration: 1500, category: .cardio),
            
            // ストレッチ
            Exercise(name: "全身ストレッチ", sets: 1, reps: 0, weight: nil, duration: 600, category: .flexibility),
            Exercise(name: "ヨガ", sets: 1, reps: 0, weight: nil, duration: 1800, category: .flexibility)
        ]
    }
    
    private func requestWorkoutAuthorization() {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
            if success {
                print("ワークアウト権限が許可されました")
                DispatchQueue.main.async {
                    self.fetchWorkouts()
                }
            } else {
                print("ワークアウト権限エラー: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    func fetchWorkouts() {
        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-60*60*24*30), end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: 50, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let error = error {
                print("ワークアウト取得エラー: \(error.localizedDescription)")
                return
            }
            
            guard let workoutSamples = samples as? [HKWorkout] else { return }
            
            DispatchQueue.main.async {
                self.workouts = workoutSamples.map { workout in
                    Workout(
                        name: workout.workoutActivityType.name,
                        type: workout.workoutActivityType,
                        duration: workout.duration,
                        calories: workout.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) ?? 0,
                        date: workout.endDate,
                        notes: nil
                    )
                }
                self.calculateWorkoutStats()
                self.printWorkoutSummary()
            }
        }
        
        healthStore.execute(query)
    }
    
    private func calculateWorkoutStats() {
        let calendar = Calendar.current
        let now = Date()
        
        // 週間の運動時間
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        weeklyWorkoutMinutes = workouts
            .filter { $0.date >= weekStart }
            .reduce(0) { $0 + $1.duration / 60 }
        
        // 月間の運動時間
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        monthlyWorkoutMinutes = workouts
            .filter { $0.date >= monthStart }
            .reduce(0) { $0 + $1.duration / 60 }
    }
    
    private func printWorkoutSummary() {
        let strengthWorkouts = workouts.filter { workout in
            workout.type == .functionalStrengthTraining || 
            workout.type == .traditionalStrengthTraining ||
            workout.type == .coreTraining
        }
        
        print("=== ワークアウトサマリー ===")
        print("総ワークアウト数: \(workouts.count)")
        print("筋トレ回数: \(strengthWorkouts.count)")
        
        if !strengthWorkouts.isEmpty {
            let totalStrengthTime = strengthWorkouts.reduce(0) { $0 + $1.duration }
            let avgStrengthTime = totalStrengthTime / Double(strengthWorkouts.count)
            print("筋トレ総時間: \(Int(totalStrengthTime/60))分")
            print("平均筋トレ時間: \(Int(avgStrengthTime/60))分")
            
            // 最近の筋トレ
            let recentStrength = strengthWorkouts.prefix(3)
            print("最近の筋トレ:")
            for workout in recentStrength {
                print("- \(workout.name): \(Int(workout.duration/60))分 (\(DateUtil.shared.formatJapaneseDate(workout.date)))")
            }
        }
        
        print("週間運動時間: \(Int(weeklyWorkoutMinutes))分")
        print("月間運動時間: \(Int(monthlyWorkoutMinutes))分")
        print("========================")
    }
    
    func startWorkout(type: HKWorkoutActivityType) {
        // 実際のアプリでは、HKWorkoutSessionを使用してワークアウトを開始
        print("ワークアウト開始: \(type.name)")
    }
    
    func endWorkout() {
        // 実際のアプリでは、HKWorkoutSessionを終了してデータを保存
        print("ワークアウト終了")
    }
}

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .walking: return "ウォーキング"
        case .running: return "ランニング"
        case .cycling: return "サイクリング"
        case .swimming: return "スイミング"
        case .yoga: return "ヨガ"
        case .functionalStrengthTraining: return "筋力トレーニング"
        case .flexibility: return "ストレッチ"
        case .coreTraining: return "コアトレーニング"
        case .traditionalStrengthTraining: return "筋力トレーニング"
        case .mixedCardio: return "混合有酸素運動"
        case .highIntensityIntervalTraining: return "HIIT"
        case .pilates: return "ピラティス"
        case .barre: return "バレエ"
        case .dance: return "ダンス"
        case .mindAndBody: return "マインド&ボディ"
        case .stepTraining: return "ステップトレーニング"
        case .fitnessGaming: return "フィットネスゲーム"
        case .boxing: return "ボクシング"
        case .kickboxing: return "キックボクシング"
        case .martialArts: return "格闘技"
        case .rowing: return "ローイング"
        case .elliptical: return "エリプティカル"
        case .stairClimbing: return "階段上り"
        case .stairs: return "階段"
        case .other: return "その他の運動"
        default: return "その他の運動"
        }
    }
} 