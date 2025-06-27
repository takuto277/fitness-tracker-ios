import SwiftUI

struct NutritionView: View {
    @ObservedObject var nutritionManager: NutritionManager
    @State private var showingAddMeal = false
    @State private var selectedMeal: Meal?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 今日の栄養サマリー
                    if let todayNutrition = nutritionManager.todayNutrition {
                        VStack(spacing: 15) {
                            Text("今日の栄養")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            // カロリー進捗
                            VStack(spacing: 10) {
                                HStack {
                                    Text("カロリー")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(Int(todayNutrition.calories))/\(Int(nutritionManager.dailyCalorieGoal)) kcal")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                ProgressView(value: nutritionManager.getCalorieProgress())
                                    .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                            }
                            
                            // 栄養素バー
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                                NutritionCard(
                                    title: "タンパク質",
                                    value: String(format: "%.1f", todayNutrition.protein),
                                    unit: "g",
                                    target: nutritionManager.dailyProteinGoal,
                                    color: .blue
                                )
                                
                                NutritionCard(
                                    title: "炭水化物",
                                    value: String(format: "%.1f", todayNutrition.carbs),
                                    unit: "g",
                                    target: 250,
                                    color: .green
                                )
                                
                                NutritionCard(
                                    title: "脂質",
                                    value: String(format: "%.1f", todayNutrition.fat),
                                    unit: "g",
                                    target: 65,
                                    color: .red
                                )
                            }
                            
                            // 水分摂取
                            VStack(spacing: 10) {
                                HStack {
                                    Text("水分摂取")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(Int(todayNutrition.water))/\(Int(nutritionManager.dailyWaterGoal)) ml")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                ProgressView(value: nutritionManager.getWaterProgress())
                                    .progressViewStyle(LinearProgressViewStyle(tint: .cyan))
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    
                    // 食事記録
                    VStack(spacing: 15) {
                        HStack {
                            Text("食事記録")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                showingAddMeal = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        if nutritionManager.meals.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                
                                Text("まだ食事記録がありません")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Button("食事を追加") {
                                    showingAddMeal = true
                                }
                                .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(nutritionManager.meals, id: \.id) { meal in
                                    MealCard(meal: meal) {
                                        selectedMeal = meal
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // 栄養アドバイス
                    VStack(spacing: 15) {
                        Text("栄養アドバイス")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            NutritionAdviceCard(
                                title: "タンパク質",
                                description: "筋肉の修復と成長に重要です。1日体重1kgあたり1.2-1.6gを目標にしましょう。",
                                icon: "dumbbell.fill",
                                color: .blue
                            )
                            
                            NutritionAdviceCard(
                                title: "水分",
                                description: "1日2Lの水分摂取を心がけましょう。運動時はさらに多めに摂取してください。",
                                icon: "drop.fill",
                                color: .cyan
                            )
                            
                            NutritionAdviceCard(
                                title: "バランス",
                                description: "タンパク質、炭水化物、脂質のバランスを意識した食事を心がけましょう。",
                                icon: "chart.pie.fill",
                                color: .green
                            )
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("栄養管理")
            .sheet(isPresented: $showingAddMeal) {
                AddMealView(nutritionManager: nutritionManager)
            }
            .sheet(item: $selectedMeal) { meal in
                MealDetailView(meal: meal)
            }
        }
    }
}

struct NutritionCard: View {
    let title: String
    let value: String
    let unit: String
    let target: Double
    let color: Color
    
    var progress: Double {
        guard let value = Double(value) else { return 0 }
        return min(value / target, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(height: 4)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct MealCard: View {
    let meal: Meal
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: meal.type.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(Int(meal.calories))kcal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(meal.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(meal.date, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
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

struct NutritionAdviceCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AddMealView: View {
    @ObservedObject var nutritionManager: NutritionManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var mealName = ""
    @State private var selectedType: MealType = .breakfast
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("食事の詳細") {
                    TextField("食事名", text: $mealName)
                    
                    Picker("食事タイプ", selection: $selectedType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                }
                
                Section("栄養素") {
                    HStack {
                        Text("カロリー")
                        Spacer()
                        TextField("kcal", text: $calories)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("タンパク質")
                        Spacer()
                        TextField("g", text: $protein)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("炭水化物")
                        Spacer()
                        TextField("g", text: $carbs)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("脂質")
                        Spacer()
                        TextField("g", text: $fat)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("メモ") {
                    TextField("メモを入力", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("食事追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveMeal()
                    }
                    .disabled(mealName.isEmpty)
                }
            }
        }
    }
    
    private func saveMeal() {
        let meal = Meal(
            name: mealName,
            type: selectedType,
            calories: Double(calories) ?? 0,
            protein: Double(protein) ?? 0,
            carbs: Double(carbs) ?? 0,
            fat: Double(fat) ?? 0,
            date: Date(),
            notes: notes.isEmpty ? nil : notes
        )
        
        nutritionManager.addMeal(meal)
        dismiss()
    }
}

struct MealDetailView: View {
    let meal: Meal
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 食事ヘッダー
                    VStack(spacing: 15) {
                        Image(systemName: meal.type.icon)
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text(meal.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(meal.type.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(meal.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // 栄養素詳細
                    VStack(spacing: 15) {
                        Text("栄養素")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                            NutritionDetailCard(title: "カロリー", value: "\(Int(meal.calories))", unit: "kcal", color: .orange)
                            NutritionDetailCard(title: "タンパク質", value: String(format: "%.1f", meal.protein), unit: "g", color: .blue)
                            NutritionDetailCard(title: "炭水化物", value: String(format: "%.1f", meal.carbs), unit: "g", color: .green)
                            NutritionDetailCard(title: "脂質", value: String(format: "%.1f", meal.fat), unit: "g", color: .red)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // メモ
                    if let notes = meal.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("メモ")
                                .font(.headline)
                            
                            Text(notes)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("食事詳細")
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

struct NutritionDetailCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    NutritionView(nutritionManager: NutritionManager())
} 