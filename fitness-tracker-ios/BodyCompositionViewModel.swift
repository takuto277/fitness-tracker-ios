import SwiftUI
import HealthKit
import Combine

// MARK: - Output
struct BodyCompositionOutput {
    var currentWeight: Double = 0
    var currentMuscleMass: Double = 0
    var currentBodyFatPercentage: Double = 0
    var currentBasalMetabolicRate: Double = 0
    var weightChange: Double = 0
    var muscleMassChange: Double = 0
    var bodyFatChange: Double = 0
    var bodyCompositionHistory: [BodyCompositionData] = []
    var isLoading: Bool = false
    var showingInputSheet: Bool = false
    var selectedDataType: BodyDataType = .weight
}

// MARK: - ViewModel
@MainActor
class BodyCompositionViewModel: ObservableObject {
    @Published var output = BodyCompositionOutput()
    
    let bodyCompositionManager: BodyCompositionManager
    private var cancellables = Set<AnyCancellable>()
    
    init(bodyCompositionManager: BodyCompositionManager) {
        self.bodyCompositionManager = bodyCompositionManager
        setupBindings()
    }
    
    private func setupBindings() {
        // BodyCompositionManagerのデータ変更を監視
        bodyCompositionManager.$currentWeight
            .assign(to: \.output.currentWeight, on: self)
            .store(in: &cancellables)
        
        bodyCompositionManager.$currentMuscleMass
            .assign(to: \.output.currentMuscleMass, on: self)
            .store(in: &cancellables)
        
        bodyCompositionManager.$currentBodyFatPercentage
            .assign(to: \.output.currentBodyFatPercentage, on: self)
            .store(in: &cancellables)
        
        bodyCompositionManager.$currentBasalMetabolicRate
            .assign(to: \.output.currentBasalMetabolicRate, on: self)
            .store(in: &cancellables)
        
        bodyCompositionManager.$bodyCompositionHistory
            .assign(to: \.output.bodyCompositionHistory, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    func refreshData() async {
        output.isLoading = true
        bodyCompositionManager.fetchLatestBodyCompositionData()
        bodyCompositionManager.fetchBodyCompositionHistory()
        updateChanges()
        output.isLoading = false
    }
    
    private func updateChanges() {
        output.weightChange = bodyCompositionManager.getWeightChange()
        output.muscleMassChange = bodyCompositionManager.getMuscleMassChange()
        output.bodyFatChange = bodyCompositionManager.getBodyFatChange()
    }
    
    func showInputSheet(for dataType: BodyDataType) {
        output.selectedDataType = dataType
        output.showingInputSheet = true
    }
    
    func hideInputSheet() {
        output.showingInputSheet = false
    }
    
    func addWeightData(weight: Double, date: Date = Date()) async {
        bodyCompositionManager.addWeightData(weight: weight, date: date)
        updateChanges()
    }
    
    func addMuscleMassData(muscleMass: Double, date: Date = Date()) async {
        bodyCompositionManager.addMuscleMassData(muscleMass: muscleMass, date: date)
        updateChanges()
    }
    
    func addBodyFatPercentageData(bodyFatPercentage: Double, date: Date = Date()) async {
        bodyCompositionManager.addBodyFatPercentageData(bodyFatPercentage: bodyFatPercentage, date: date)
        updateChanges()
    }
} 