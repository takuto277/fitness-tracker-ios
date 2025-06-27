import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var stepCount: Int = 0
    @Published var heartRate: Double = 0.0
    @Published var activeEnergy: Double = 0.0
    @Published var distance: Double = 0.0
    @Published var isAuthorized = false
    @Published var authorizationStatus: String = "未確認"
    @Published var isHealthKitAvailable = false
    
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
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        // 書き込み権限を要求するデータタイプ
        let typesToWrite: Set<HKSampleType> = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
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
    
    func fetchTodayData() {
        fetchStepCount()
        fetchHeartRate()
        fetchActiveEnergy()
        fetchDistance()
    }
    
    private func fetchStepCount() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        // 過去7日間のデータを取得
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if let error = error {
                print("歩数取得エラー: \(error.localizedDescription)")
                return
            }
            
            guard let result = result, let sum = result.sumQuantity() else {
                print("歩数データが見つかりません")
                return
            }
            
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            print("取得した歩数: \(steps)")
            
            DispatchQueue.main.async {
                self.stepCount = steps
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
    
    private func fetchDistance() {
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        // 過去7日間のデータを取得
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if let error = error {
                print("距離取得エラー: \(error.localizedDescription)")
                return
            }
            
            guard let result = result, let sum = result.sumQuantity() else {
                print("距離データが見つかりません")
                return
            }
            
            let distance = sum.doubleValue(for: HKUnit.meter())
            print("取得した距離: \(distance)")
            
            DispatchQueue.main.async {
                self.distance = distance
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