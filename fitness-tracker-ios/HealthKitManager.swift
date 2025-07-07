import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var weeklyWorkoutCount: Int = 0
    @Published var heartRate: Double = 0.0
    @Published var activeEnergy: Double = 0.0
    @Published var averageWorkoutDuration: TimeInterval = 0.0
    @Published var isAuthorized = false
    @Published var authorizationStatus: String = "未確認"
    @Published var isHealthKitAvailable = false
    
    // ワークアウト関連
    @Published var currentWorkout: HKWorkout?
    @Published var isWorkoutActive = false
    
    init() {
        // HealthKitが利用可能かチェック
        isHealthKitAvailable = HKHealthStore.isHealthDataAvailable()
        
        if isHealthKitAvailable {
            checkAuthorizationStatus()
        } else {
            authorizationStatus = "HealthKitが利用できません"
        }
    }
    
    func checkAuthorizationStatus() {
        guard isHealthKitAvailable else {
            authorizationStatus = "HealthKitが利用できません"
            return
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let status = healthStore.authorizationStatus(for: stepType)
        
        DispatchQueue.main.async {
            switch status {
            case .sharingAuthorized:
                self.isAuthorized = true
                self.authorizationStatus = "許可済み"
                self.fetchTodayData()
            case .sharingDenied:
                self.isAuthorized = false
                self.authorizationStatus = "拒否済み"
            case .notDetermined:
                self.isAuthorized = false
                self.authorizationStatus = "未決定"
            @unknown default:
                self.isAuthorized = false
                self.authorizationStatus = "不明"
            }
        }
    }
    
    func requestAuthorization() {
        guard isHealthKitAvailable else {
            print("HealthKitが利用できません")
            return
        }
        
        // 読み取り権限を要求するデータタイプ
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .height)!,
            HKQuantityType.quantityType(forIdentifier: .bodyMassIndex)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryWater)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!,
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType()
        ]
        
        // 書き込み権限を要求するデータタイプ
        let typesToWrite: Set<HKSampleType> = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryWater)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!,
            HKObjectType.workoutType()
        ]
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isAuthorized = true
                    self.authorizationStatus = "許可済み"
                    print("HealthKit権限が許可されました")
                    // 権限許可後に少し待ってからデータを取得
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.fetchTodayData()
                    }
                } else {
                    self.isAuthorized = false
                    self.authorizationStatus = "拒否済み"
                    if let error = error {
                        print("HealthKit権限エラー: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // ワークアウト開始
    func startWorkout(type: HKWorkoutActivityType) {
        let startDate = Date()
        let workout = HKWorkout(activityType: type, start: startDate, end: startDate)
        
        healthStore.save(workout) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.currentWorkout = workout
                    self.isWorkoutActive = true
                    print("ワークアウトを開始しました: \(type.displayName)")
                    
                    // ワークアウト開始後にリアルタイムデータの記録を開始
                    self.startRealTimeDataRecording()
                } else {
                    print("ワークアウト開始エラー: \(error?.localizedDescription ?? "")")
                }
            }
        }
    }
    
    // ワークアウト終了
    func endWorkout() {
        guard let workout = currentWorkout else { return }
        
        let endDate = Date()
        
        // ワークアウト中の総消費カロリーを計算
        let totalCalories = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: self.activeEnergy)
        
        let updatedWorkout = HKWorkout(
            activityType: workout.workoutActivityType,
            start: workout.startDate,
            end: endDate,
            duration: endDate.timeIntervalSince(workout.startDate),
            totalEnergyBurned: totalCalories,
            totalDistance: nil,
            metadata: [
                "app_name": "FitnessTracker",
                "workout_type": workout.workoutActivityType.displayName
            ]
        )
        
        healthStore.save(updatedWorkout) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.currentWorkout = nil
                    self.isWorkoutActive = false
                    print("ワークアウトを終了しました")
                    
                    // リアルタイムデータ記録を停止
                    self.stopRealTimeDataRecording()
                } else {
                    print("ワークアウト終了エラー: \(error?.localizedDescription ?? "")")
                }
            }
        }
    }
    
    // MARK: - Real-time Data Recording
    
    private var realTimeDataTimer: Timer?
    
    /// リアルタイムデータ記録を開始
    private func startRealTimeDataRecording() {
        // 1秒ごとにデータを記録
        realTimeDataTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.recordRealTimeData()
        }
    }
    
    /// リアルタイムデータ記録を停止
    private func stopRealTimeDataRecording() {
        realTimeDataTimer?.invalidate()
        realTimeDataTimer = nil
    }
    
    /// リアルタイムデータを記録
    private func recordRealTimeData() {
        guard isWorkoutActive else { return }
        
        // 権限が不足している場合は要求
        if !isAuthorized {
            requestAuthorization()
            return
        }
        
        // 心拍数を記録
        if heartRate > 0 {
            recordHeartRate(heartRate)
        }
        
        // 消費カロリーを記録
        if activeEnergy > 0 {
            recordActiveEnergy(activeEnergy)
        }
    }
    
    /// 心拍数を記録
    private func recordHeartRate(_ heartRate: Double) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        // 権限チェック
        let status = healthStore.authorizationStatus(for: heartRateType)
        guard status == .sharingAuthorized else {
            print("心拍数記録エラー: Not authorized (Status: \(status))")
            return
        }
        
        let heartRateQuantity = HKQuantity(unit: HKUnit(from: "count/min"), doubleValue: heartRate)
        let heartRateSample = HKQuantitySample(
            type: heartRateType,
            quantity: heartRateQuantity,
            start: Date(),
            end: Date(),
            device: nil,
            metadata: [
                "workout_session": "active"
            ]
        )
        
        healthStore.save(heartRateSample) { success, error in
            if !success {
                print("心拍数記録エラー: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    /// 消費カロリーを記録
    private func recordActiveEnergy(_ energy: Double) {
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        // 権限チェック
        let status = healthStore.authorizationStatus(for: energyType)
        guard status == .sharingAuthorized else {
            print("消費カロリー記録エラー: Not authorized (Status: \(status))")
            return
        }
        
        let energyQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: energy)
        let energySample = HKQuantitySample(
            type: energyType,
            quantity: energyQuantity,
            start: Date(),
            end: Date(),
            device: nil,
            metadata: [
                "workout_session": "active"
            ]
        )
        
        healthStore.save(energySample) { success, error in
            if !success {
                print("消費カロリー記録エラー: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    /// 筋トレセットデータを記録
    func recordStrengthTrainingSet(reps: Int, weight: Double, exercise: String) {
        guard isWorkoutActive else { return }
        
        // セットデータをメタデータとして記録
        let metadata: [String: Any] = [
            "exercise_type": exercise,
            "reps": reps,
            "weight_kg": weight,
            "set_number": 1, // 実際のアプリではセット数を管理
            "workout_session": "active"
        ]
        
        // 消費カロリーを推定して記録
        let estimatedCalories = Double(reps) * weight * 0.1 // 簡易計算
        recordActiveEnergy(estimatedCalories)
        
        print("筋トレセット記録: \(exercise) - \(reps)回 × \(weight)kg")
    }
    
    func fetchTodayData() {
        fetchWeeklyWorkoutCount()
        fetchHeartRate()
        fetchActiveEnergy()
        fetchAverageWorkoutDuration()
    }
    
    private func fetchWeeklyWorkoutCount() {
        let workoutType = HKObjectType.workoutType()
        // 過去7日間の筋トレデータを取得
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            if let error = error {
                print("筋トレデータ取得エラー: \(error.localizedDescription)")
                return
            }
            
            let strengthWorkouts = samples?.compactMap { $0 as? HKWorkout }
                .filter { $0.workoutActivityType == .traditionalStrengthTraining } ?? []
            
            let workoutCount = strengthWorkouts.count
            print("取得した筋トレ回数: \(workoutCount)")
            
            DispatchQueue.main.async {
                self.weeklyWorkoutCount = workoutCount
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchHeartRate() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        // 過去24時間のデータを取得
        let startDate = Calendar.current.date(byAdding: .hour, value: -24, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let error = error {
                print("心拍数取得エラー: \(error.localizedDescription)")
                return
            }
            
            guard let sample = samples?.first as? HKQuantitySample else {
                print("心拍数データが見つかりません")
                return
            }
            
            let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            print("取得した心拍数: \(heartRate)")
            
            DispatchQueue.main.async {
                self.heartRate = heartRate
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchActiveEnergy() {
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        // 過去7日間のデータを取得
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if let error = error {
                print("消費カロリー取得エラー: \(error.localizedDescription)")
                return
            }
            
            guard let result = result, let sum = result.sumQuantity() else {
                print("消費カロリーデータが見つかりません")
                return
            }
            
            let energy = sum.doubleValue(for: HKUnit.kilocalorie())
            print("取得した消費カロリー: \(energy)")
            
            DispatchQueue.main.async {
                self.activeEnergy = energy
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchAverageWorkoutDuration() {
        let workoutType = HKObjectType.workoutType()
        // 過去7日間の筋トレデータを取得
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            if let error = error {
                print("筋トレ時間取得エラー: \(error.localizedDescription)")
                return
            }
            
            let strengthWorkouts = samples?.compactMap { $0 as? HKWorkout }
                .filter { $0.workoutActivityType == .traditionalStrengthTraining } ?? []
            
            let totalDuration = strengthWorkouts.reduce(0) { $0 + TimeInterval($1.duration) }
            let averageDuration = strengthWorkouts.isEmpty ? 0 : totalDuration / Double(strengthWorkouts.count)
            
            print("取得した平均筋トレ時間: \(averageDuration)秒")
            
            DispatchQueue.main.async {
                self.averageWorkoutDuration = averageDuration
            }
        }
        
        healthStore.execute(query)
    }
    
    func addWaterIntake(amount: Double) {
        let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
        let waterQuantity = HKQuantity(unit: HKUnit.fluidOunceUS(), doubleValue: amount)
        let waterSample = HKQuantitySample(type: waterType, quantity: waterQuantity, start: Date(), end: Date())
        
        healthStore.save(waterSample) { success, error in
            if success {
                print("水分摂取量を記録しました")
            } else {
                print("水分摂取量の記録に失敗しました: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    // MARK: - Workout Data Fetching
    
    /// 指定期間のワークアウトデータを取得
    func fetchWorkouts(from startDate: Date, to endDate: Date) async -> [HKWorkout] {
        return await withCheckedContinuation { continuation in
            let workoutType = HKObjectType.workoutType()
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            
            let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    print("ワークアウトデータ取得エラー: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }
                
                let workouts = samples as? [HKWorkout] ?? []
                print("取得したワークアウト数: \(workouts.count)")
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// 今日のワークアウトデータを取得
    func fetchTodayWorkouts() async -> [HKWorkout] {
        let startDate = Date().startOfDay
        let endDate = Date().endOfDay
        return await fetchWorkouts(from: startDate, to: endDate)
    }
    
    /// 過去7日間のワークアウトデータを取得
    func fetchWeeklyWorkouts() async -> [HKWorkout] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        return await fetchWorkouts(from: startDate, to: endDate)
    }
    
    /// 過去30日間のワークアウトデータを取得
    func fetchMonthlyWorkouts() async -> [HKWorkout] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        return await fetchWorkouts(from: startDate, to: endDate)
    }
    
    /// 最近の筋トレワークアウトを取得
    func fetchRecentStrengthWorkouts(completion: @escaping ([HKWorkout]) -> Void) {
        let workoutType = HKObjectType.workoutType()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: 5, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let error = error {
                print("最近の筋トレ取得エラー: \(error.localizedDescription)")
                completion([])
                return
            }
            
            let strengthWorkouts = samples?.compactMap { $0 as? HKWorkout }
                .filter { $0.workoutActivityType == .traditionalStrengthTraining } ?? []
            
            print("取得した最近の筋トレ数: \(strengthWorkouts.count)")
            completion(strengthWorkouts)
        }
        
        healthStore.execute(query)
    }
    
    // テスト用のダミーデータを追加
    func addTestData() {
        addTestStepCount()
        addTestHeartRate()
        addTestActiveEnergy()
        addTestDistance()
    }
    
    private func addTestStepCount() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let stepQuantity = HKQuantity(unit: HKUnit.count(), doubleValue: 5000)
        let stepSample = HKQuantitySample(type: stepType, quantity: stepQuantity, start: Date().addingTimeInterval(-3600), end: Date())
        
        healthStore.save(stepSample) { success, error in
            if success {
                print("テスト歩数データを追加しました")
                DispatchQueue.main.async {
                    self.fetchTodayData()
                }
            } else {
                print("テスト歩数データの追加に失敗しました: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    private func addTestHeartRate() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let heartRateQuantity = HKQuantity(unit: HKUnit(from: "count/min"), doubleValue: 72)
        let heartRateSample = HKQuantitySample(type: heartRateType, quantity: heartRateQuantity, start: Date().addingTimeInterval(-1800), end: Date())
        
        healthStore.save(heartRateSample) { success, error in
            if success {
                print("テスト心拍数データを追加しました")
                DispatchQueue.main.async {
                    self.fetchTodayData()
                }
            } else {
                print("テスト心拍数データの追加に失敗しました: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    private func addTestActiveEnergy() {
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let energyQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: 250)
        let energySample = HKQuantitySample(type: energyType, quantity: energyQuantity, start: Date().addingTimeInterval(-7200), end: Date())
        
        healthStore.save(energySample) { success, error in
            if success {
                print("テスト消費カロリーデータを追加しました")
                DispatchQueue.main.async {
                    self.fetchTodayData()
                }
            } else {
                print("テスト消費カロリーデータの追加に失敗しました: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    private func addTestDistance() {
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let distanceQuantity = HKQuantity(unit: HKUnit.meter(), doubleValue: 3000)
        let distanceSample = HKQuantitySample(type: distanceType, quantity: distanceQuantity, start: Date().addingTimeInterval(-5400), end: Date())
        
        healthStore.save(distanceSample) { success, error in
            if success {
                print("テスト距離データを追加しました")
                DispatchQueue.main.async {
                    self.fetchTodayData()
                }
            } else {
                print("テスト距離データの追加に失敗しました: \(error?.localizedDescription ?? "")")
            }
        }
    }
}

// Date拡張
extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
} 