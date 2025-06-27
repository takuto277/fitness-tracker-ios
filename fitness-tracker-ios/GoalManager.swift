import Foundation
import SwiftUI

struct Goal: Identifiable {
    let id = UUID()
    let title: String
    let targetValue: Double
    let currentValue: Double
    let unit: String
    let type: GoalType
    let deadline: Date
    let isCompleted: Bool
    
    var progress: Double {
        return min(currentValue / targetValue, 1.0)
    }
    
    var progressPercentage: Int {
        return Int(progress * 100)
    }
}

enum GoalType: String, CaseIterable {
    case weight = "体重"
    case steps = "歩数"
    case calories = "消費カロリー"
    case exercise = "運動時間"
    case water = "水分摂取"
    case sleep = "睡眠時間"
    
    var icon: String {
        switch self {
        case .weight: return "scalemass"
        case .steps: return "figure.walk"
        case .calories: return "flame"
        case .exercise: return "dumbbell"
        case .water: return "drop"
        case .sleep: return "bed.double"
        }
    }
    
    var color: Color {
        switch self {
        case .weight: return .purple
        case .steps: return .blue
        case .calories: return .orange
        case .exercise: return .green
        case .water: return .cyan
        case .sleep: return .indigo
        }
    }
}

class GoalManager: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var weeklyProgress: [String: Double] = [:]
    @Published var monthlyProgress: [String: Double] = [:]
    
    init() {
        setupDefaultGoals()
    }
    
    private func setupDefaultGoals() {
        let twoMonthsFromNow = Calendar.current.date(byAdding: .month, value: 2, to: Date()) ?? Date()
        
        goals = [
            Goal(title: "体重を5kg減らす", targetValue: 5.0, currentValue: 0.0, unit: "kg", type: .weight, deadline: twoMonthsFromNow, isCompleted: false),
            Goal(title: "1日10,000歩", targetValue: 10000, currentValue: 0.0, unit: "歩", type: .steps, deadline: twoMonthsFromNow, isCompleted: false),
            Goal(title: "1日300kcal消費", targetValue: 300, currentValue: 0.0, unit: "kcal", type: .calories, deadline: twoMonthsFromNow, isCompleted: false),
            Goal(title: "1日30分運動", targetValue: 30, currentValue: 0.0, unit: "分", type: .exercise, deadline: twoMonthsFromNow, isCompleted: false),
            Goal(title: "1日2L水分摂取", targetValue: 2000, currentValue: 0.0, unit: "ml", type: .water, deadline: twoMonthsFromNow, isCompleted: false),
            Goal(title: "1日7時間睡眠", targetValue: 7, currentValue: 0.0, unit: "時間", type: .sleep, deadline: twoMonthsFromNow, isCompleted: false)
        ]
    }
    
    func updateGoalProgress(type: GoalType, currentValue: Double) {
        if let index = goals.firstIndex(where: { $0.type == type }) {
            goals[index] = Goal(
                title: goals[index].title,
                targetValue: goals[index].targetValue,
                currentValue: currentValue,
                unit: goals[index].unit,
                type: goals[index].type,
                deadline: goals[index].deadline,
                isCompleted: currentValue >= goals[index].targetValue
            )
        }
    }
    
    func getCompletedGoals() -> [Goal] {
        return goals.filter { $0.isCompleted }
    }
    
    func getOverallProgress() -> Double {
        let completedCount = getCompletedGoals().count
        return Double(completedCount) / Double(goals.count)
    }
} 