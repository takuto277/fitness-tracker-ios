import SwiftUI
import HealthKit

struct BodyCompositionView: View {
    @StateObject private var viewModel: BodyCompositionViewModel
    
    init(bodyCompositionManager: BodyCompositionManager) {
        self._viewModel = StateObject(wrappedValue: BodyCompositionViewModel(
            bodyCompositionManager: bodyCompositionManager
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 現在の体組成データ
                    currentDataSection
                    
                    // 体組成データ入力
                    inputSection
                    
                    // 履歴グラフ
                    historySection
                    
                    // 目標設定
                    goalsSection
                }
                .padding()
            }
            .navigationTitle("体組成管理")
            .sheet(isPresented: $viewModel.output.showingInputSheet) {
                BodyCompositionInputView(
                    dataType: viewModel.output.selectedDataType,
                    viewModel: viewModel
                )
            }
        }
    }
    
    private var currentDataSection: some View {
        VStack(spacing: 15) {
            Text("現在の体組成")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                BodyCompositionCard(
                    title: "体重",
                    value: "\(String(format: "%.1f", viewModel.output.currentWeight))",
                    unit: "kg",
                    change: viewModel.output.weightChange,
                    icon: "scalemass.fill",
                    color: .purple
                )
                
                BodyCompositionCard(
                    title: "筋肉量",
                    value: "\(String(format: "%.1f", viewModel.output.currentMuscleMass))",
                    unit: "kg",
                    change: viewModel.output.muscleMassChange,
                    icon: "dumbbell.fill",
                    color: .green
                )
                
                BodyCompositionCard(
                    title: "体脂肪率",
                    value: "\(String(format: "%.1f", viewModel.output.currentBodyFatPercentage))",
                    unit: "%",
                    change: viewModel.output.bodyFatChange,
                    icon: "chart.pie.fill",
                    color: .orange
                )
                
                BodyCompositionCard(
                    title: "基礎代謝",
                    value: "\(Int(viewModel.output.currentBasalMetabolicRate))",
                    unit: "kcal",
                    change: 0,
                    icon: "flame.fill",
                    color: .red
                )
            }
        }
    }
    
    private var inputSection: some View {
        VStack(spacing: 15) {
            Text("データ入力")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                ForEach(BodyDataType.allCases, id: \.self) { dataType in
                    Button(action: {
                        viewModel.showInputSheet(for: dataType)
                    }) {
                        VStack {
                            Image(systemName: dataType.icon)
                                .font(.title2)
                                .foregroundColor(dataType.color)
                            Text(dataType.displayName)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        .frame(height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(dataType.color.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(dataType.color, lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
    }
    
    private var historySection: some View {
        VStack(spacing: 15) {
            Text("履歴")
                .font(.headline)
            
            // 簡易的な履歴表示（実際のアプリではグラフを実装）
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(viewModel.output.bodyCompositionHistory.prefix(5))) { record in
                    HStack {
                        Text(DateUtil.shared.formatJapaneseDate(record.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("体重: \(String(format: "%.1f", record.weight ?? 0))kg")
                            .font(.caption)
                        
                        Text("筋肉量: \(String(format: "%.1f", record.muscleMass ?? 0))kg")
                            .font(.caption)
                        
                        Text("体脂肪率: \(String(format: "%.1f", record.bodyFatPercentage ?? 0))%")
                            .font(.caption)
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(5)
                }
            }
        }
    }
    
    private var goalsSection: some View {
        VStack(spacing: 15) {
            Text("目標設定")
                .font(.headline)
            
            VStack(spacing: 10) {
                GoalRow(
                    title: "目標体重",
                    current: viewModel.output.currentWeight,
                    target: 65.0, // 実際のアプリでは設定から取得
                    unit: "kg"
                )
                
                GoalRow(
                    title: "目標筋肉量",
                    current: viewModel.output.currentMuscleMass,
                    target: 45.0,
                    unit: "kg"
                )
                
                GoalRow(
                    title: "目標体脂肪率",
                    current: viewModel.output.currentBodyFatPercentage,
                    target: 15.0,
                    unit: "%"
                )
            }
        }
    }
}

struct BodyCompositionCard: View {
    let title: String
    let value: String
    let unit: String
    let change: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if change != 0 {
                Text(String(format: "%+.1f", change))
                    .font(.caption)
                    .foregroundColor(change > 0 ? .green : .red)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct GoalRow: View {
    let title: String
    let current: Double
    let target: Double
    let unit: String
    
    private var progress: Double {
        if target > current {
            return current / target
        } else {
            return target / current
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(String(format: "%.1f", current))/\(String(format: "%.1f", target))\(unit)")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

enum BodyDataType: CaseIterable {
    case weight, muscleMass, bodyFatPercentage
    
    var displayName: String {
        switch self {
        case .weight:
            return "体重"
        case .muscleMass:
            return "筋肉量"
        case .bodyFatPercentage:
            return "体脂肪率"
        }
    }
    
    var icon: String {
        switch self {
        case .weight:
            return "scalemass.fill"
        case .muscleMass:
            return "dumbbell.fill"
        case .bodyFatPercentage:
            return "chart.pie.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .weight:
            return .purple
        case .muscleMass:
            return .green
        case .bodyFatPercentage:
            return .orange
        }
    }
}

struct BodyCompositionInputView: View {
    let dataType: BodyDataType
    @ObservedObject var viewModel: BodyCompositionViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var value: String = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("\(dataType.displayName)を入力")) {
                    HStack {
                        TextField("値", text: $value)
                            .keyboardType(.decimalPad)
                        
                        Text(dataType == .bodyFatPercentage ? "%" : "kg")
                            .foregroundColor(.secondary)
                    }
                    
                    DatePicker("日付", selection: $date, displayedComponents: .date)
                }
                
                Section {
                    Button("保存") {
                        saveData()
                    }
                    .disabled(value.isEmpty)
                }
            }
            .navigationTitle("\(dataType.displayName)入力")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveData() {
        guard let doubleValue = Double(value) else { return }
        
        Task {
            switch dataType {
            case .weight:
                await viewModel.addWeightData(weight: doubleValue, date: date)
            case .muscleMass:
                await viewModel.addMuscleMassData(muscleMass: doubleValue, date: date)
            case .bodyFatPercentage:
                await viewModel.addBodyFatPercentageData(bodyFatPercentage: doubleValue, date: date)
            }
            
            dismiss()
        }
    }
} 