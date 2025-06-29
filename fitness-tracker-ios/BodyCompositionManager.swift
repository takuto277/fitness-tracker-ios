import Foundation
import HealthKit
import SwiftUI

class BodyCompositionManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var currentWeight: Double = 0
    @Published var currentBodyFatPercentage: Double = 0
    @Published var currentMuscleMass: Double = 0
    @Published var currentBasalMetabolicRate: Double = 0
    @Published var currentBMI: Double = 0
    @Published var currentVisceralFatLevel: Double = 0
    
    @Published var weightHistory: [BodyCompositionData] = []
    @Published var bodyCompositionHistory: [BodyCompositionData] = []
    @Published var isDataAvailable = false
    @Published var lastUpdateDate: Date?
    
    // 目標設定
    @Published var targetWeight: Double = 0
    @Published var targetBodyFatPercentage: Double = 0
    @Published var targetMuscleMass: Double = 0
    
    init() {
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!,
            HKQuantityType.quantityType(forIdentifier: .leanBodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .bodyMassIndex)!,
            HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .height)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                print("体組成データ権限が許可されました")
                DispatchQueue.main.async {
                    self.fetchLatestBodyCompositionData()
                    self.fetchBodyCompositionHistory()
                }
            } else {
                print("体組成データ権限エラー: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    func fetchLatestBodyCompositionData() {
        fetchLatestWeight()
        fetchLatestBodyFatPercentage()
        fetchLatestMuscleMass()
        fetchLatestBasalMetabolicRate()
        fetchLatestBMI()
        fetchLatestVisceralFatLevel()
    }
    
    private func fetchLatestWeight() {
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let predicate = HKQuery.predicateForSamples(withStart: nil, end: nil, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let sample = samples?.first as? HKQuantitySample {
                let weight = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                DispatchQueue.main.async {
                    self.currentWeight = weight
                    self.lastUpdateDate = sample.endDate
                    self.isDataAvailable = true
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestBodyFatPercentage() {
        let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!
        let predicate = HKQuery.predicateForSamples(withStart: nil, end: nil, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: bodyFatType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let sample = samples?.first as? HKQuantitySample {
                let bodyFat = sample.quantity.doubleValue(for: HKUnit.percent())
                DispatchQueue.main.async {
                    self.currentBodyFatPercentage = bodyFat
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestMuscleMass() {
        let muscleType = HKQuantityType.quantityType(forIdentifier: .leanBodyMass)!
        let predicate = HKQuery.predicateForSamples(withStart: nil, end: nil, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: muscleType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let sample = samples?.first as? HKQuantitySample {
                let muscle = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                DispatchQueue.main.async {
                    self.currentMuscleMass = muscle
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestBasalMetabolicRate() {
        let bmrType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!
        let predicate = HKQuery.predicateForSamples(withStart: nil, end: nil, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: bmrType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let sample = samples?.first as? HKQuantitySample {
                let bmr = sample.quantity.doubleValue(for: HKUnit.kilocalorie())
                DispatchQueue.main.async {
                    self.currentBasalMetabolicRate = bmr
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestBMI() {
        let bmiType = HKQuantityType.quantityType(forIdentifier: .bodyMassIndex)!
        let predicate = HKQuery.predicateForSamples(withStart: nil, end: nil, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: bmiType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let sample = samples?.first as? HKQuantitySample {
                let bmi = sample.quantity.doubleValue(for: HKUnit.count())
                DispatchQueue.main.async {
                    self.currentBMI = bmi
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestVisceralFatLevel() {
        // 内臓脂肪レベルはHealthKitに直接的なデータ型がないため、
        // カスタムメタデータとして保存されている場合を想定
        // 実際のOMRONアプリでは、このデータがHealthKitに保存される可能性がある
        currentVisceralFatLevel = 0 // デフォルト値
    }
    
    func fetchBodyCompositionHistory() {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .month, value: -3, to: now)!
        
        fetchWeightHistory(startDate: startDate, endDate: now)
        fetchBodyFatHistory(startDate: startDate, endDate: now)
        fetchMuscleMassHistory(startDate: startDate, endDate: now)
    }
    
    private func fetchWeightHistory(startDate: Date, endDate: Date) {
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: 100, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let weightSamples = samples as? [HKQuantitySample] {
                DispatchQueue.main.async {
                    self.processWeightHistory(weightSamples)
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchBodyFatHistory(startDate: Date, endDate: Date) {
        let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: bodyFatType, predicate: predicate, limit: 100, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let bodyFatSamples = samples as? [HKQuantitySample] {
                DispatchQueue.main.async {
                    self.processBodyFatHistory(bodyFatSamples)
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchMuscleMassHistory(startDate: Date, endDate: Date) {
        let muscleType = HKQuantityType.quantityType(forIdentifier: .leanBodyMass)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: muscleType, predicate: predicate, limit: 100, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let muscleSamples = samples as? [HKQuantitySample] {
                DispatchQueue.main.async {
                    self.processMuscleMassHistory(muscleSamples)
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func processWeightHistory(_ samples: [HKQuantitySample]) {
        weightHistory.removeAll()
        
        for sample in samples {
            let weight = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            let date = sample.endDate
            
            weightHistory.append(BodyCompositionData(
                date: date,
                weight: weight,
                bodyFatPercentage: nil,
                muscleMass: nil,
                basalMetabolicRate: nil,
                bmi: nil,
                visceralFatLevel: nil
            ))
        }
        
        weightHistory.sort { $0.date < $1.date }
        bodyCompositionHistory = weightHistory
    }
    
    private func processBodyFatHistory(_ samples: [HKQuantitySample]) {
        for sample in samples {
            let bodyFat = sample.quantity.doubleValue(for: HKUnit.percent())
            let date = sample.endDate
            
            if let index = weightHistory.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                weightHistory[index] = BodyCompositionData(
                    date: weightHistory[index].date,
                    weight: weightHistory[index].weight,
                    bodyFatPercentage: bodyFat,
                    muscleMass: weightHistory[index].muscleMass,
                    basalMetabolicRate: weightHistory[index].basalMetabolicRate,
                    bmi: weightHistory[index].bmi,
                    visceralFatLevel: weightHistory[index].visceralFatLevel
                )
            }
        }
        bodyCompositionHistory = weightHistory
    }
    
    private func processMuscleMassHistory(_ samples: [HKQuantitySample]) {
        for sample in samples {
            let muscle = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            let date = sample.endDate
            
            if let index = weightHistory.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                weightHistory[index] = BodyCompositionData(
                    date: weightHistory[index].date,
                    weight: weightHistory[index].weight,
                    bodyFatPercentage: weightHistory[index].bodyFatPercentage,
                    muscleMass: muscle,
                    basalMetabolicRate: weightHistory[index].basalMetabolicRate,
                    bmi: weightHistory[index].bmi,
                    visceralFatLevel: weightHistory[index].visceralFatLevel
                )
            }
        }
        bodyCompositionHistory = weightHistory
    }
    
    // 分析メソッド
    func getWeightChange() -> Double {
        guard let firstWeight = weightHistory.first?.weight,
              let lastWeight = weightHistory.last?.weight else {
            return 0
        }
        return lastWeight - firstWeight
    }
    
    func getMuscleMassChange() -> Double {
        guard let firstMuscle = weightHistory.first?.muscleMass,
              let lastMuscle = weightHistory.last?.muscleMass else {
            return 0
        }
        return lastMuscle - firstMuscle
    }
    
    func getBodyFatChange() -> Double {
        guard let firstBodyFat = weightHistory.first?.bodyFatPercentage,
              let lastBodyFat = weightHistory.last?.bodyFatPercentage else {
            return 0
        }
        return lastBodyFat - firstBodyFat
    }
    
    func getBMIStatus() -> BMIStatus {
        switch currentBMI {
        case 0..<18.5:
            return .underweight
        case 18.5..<25:
            return .normal
        case 25..<30:
            return .overweight
        default:
            return .obese
        }
    }
    
    func getBodyFatStatus() -> BodyFatStatus {
        // 年齢と性別によって異なるが、一般的な基準
        switch currentBodyFatPercentage {
        case 0..<10:
            return .veryLow
        case 10..<15:
            return .low
        case 15..<20:
            return .normal
        case 20..<25:
            return .high
        default:
            return .veryHigh
        }
    }
    
    // 目標達成率
    func getWeightProgress() -> Double {
        guard targetWeight > 0 else { return 0 }
        let initialWeight = weightHistory.first?.weight ?? currentWeight
        let totalChange = initialWeight - targetWeight
        let currentChange = initialWeight - currentWeight
        
        return totalChange > 0 ? min(currentChange / totalChange, 1.0) : 0
    }
    
    func getMuscleMassProgress() -> Double {
        guard targetMuscleMass > 0 else { return 0 }
        let initialMuscle = weightHistory.first?.muscleMass ?? currentMuscleMass
        let totalChange = targetMuscleMass - initialMuscle
        let currentChange = currentMuscleMass - initialMuscle
        
        return totalChange > 0 ? min(currentChange / totalChange, 1.0) : 0
    }
    
    func getBodyFatProgress() -> Double {
        guard targetBodyFatPercentage > 0 else { return 0 }
        let initialBodyFat = weightHistory.first?.bodyFatPercentage ?? currentBodyFatPercentage
        let totalChange = initialBodyFat - targetBodyFatPercentage
        let currentChange = initialBodyFat - currentBodyFatPercentage
        
        return totalChange > 0 ? min(currentChange / totalChange, 1.0) : 0
    }
    
    // データ追加メソッド
    func addWeightData(weight: Double, date: Date = Date()) {
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let weightQuantity = HKQuantity(unit: HKUnit.gramUnit(with: .kilo), doubleValue: weight)
        let weightSample = HKQuantitySample(type: weightType, quantity: weightQuantity, start: date, end: date)
        
        healthStore.save(weightSample) { success, error in
            if success {
                print("体重データを保存しました")
                DispatchQueue.main.async {
                    self.currentWeight = weight
                    self.fetchLatestBodyCompositionData()
                }
            } else {
                print("体重データの保存に失敗しました: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    func addMuscleMassData(muscleMass: Double, date: Date = Date()) {
        let muscleType = HKQuantityType.quantityType(forIdentifier: .leanBodyMass)!
        let muscleQuantity = HKQuantity(unit: HKUnit.gramUnit(with: .kilo), doubleValue: muscleMass)
        let muscleSample = HKQuantitySample(type: muscleType, quantity: muscleQuantity, start: date, end: date)
        
        healthStore.save(muscleSample) { success, error in
            if success {
                print("筋肉量データを保存しました")
                DispatchQueue.main.async {
                    self.currentMuscleMass = muscleMass
                    self.fetchLatestBodyCompositionData()
                }
            } else {
                print("筋肉量データの保存に失敗しました: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    func addBodyFatPercentageData(bodyFatPercentage: Double, date: Date = Date()) {
        let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!
        let bodyFatQuantity = HKQuantity(unit: HKUnit.percent(), doubleValue: bodyFatPercentage)
        let bodyFatSample = HKQuantitySample(type: bodyFatType, quantity: bodyFatQuantity, start: date, end: date)
        
        healthStore.save(bodyFatSample) { success, error in
            if success {
                print("体脂肪率データを保存しました")
                DispatchQueue.main.async {
                    self.currentBodyFatPercentage = bodyFatPercentage
                    self.fetchLatestBodyCompositionData()
                }
            } else {
                print("体脂肪率データの保存に失敗しました: \(error?.localizedDescription ?? "")")
            }
        }
    }
}

// データ構造
struct BodyCompositionData: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double?
    let bodyFatPercentage: Double?
    let muscleMass: Double?
    let basalMetabolicRate: Double?
    let bmi: Double?
    let visceralFatLevel: Double?
}

enum BMIStatus {
    case underweight, normal, overweight, obese
    
    var description: String {
        switch self {
        case .underweight:
            return "低体重"
        case .normal:
            return "標準体重"
        case .overweight:
            return "過体重"
        case .obese:
            return "肥満"
        }
    }
    
    var color: Color {
        switch self {
        case .underweight, .obese:
            return .orange
        case .overweight:
            return .yellow
        case .normal:
            return .green
        }
    }
}

enum BodyFatStatus {
    case veryLow, low, normal, high, veryHigh
    
    var description: String {
        switch self {
        case .veryLow:
            return "非常に低い"
        case .low:
            return "低い"
        case .normal:
            return "適正"
        case .high:
            return "高い"
        case .veryHigh:
            return "非常に高い"
        }
    }
    
    var color: Color {
        switch self {
        case .veryLow, .veryHigh:
            return .red
        case .low, .high:
            return .orange
        case .normal:
            return .green
        }
    }
} 