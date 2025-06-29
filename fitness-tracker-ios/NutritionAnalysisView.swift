import SwiftUI
import HealthKit

struct NutritionAnalysisView: View {
    @EnvironmentObject var nutritionManager: NutritionManager
    @State private var showingInputSheet = false
    @State private var showingPhotoAnalysis = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 今日の栄養サマリー
                    nutritionSummarySection
                    
                    // 栄養素バランス
                    nutritionBalanceSection
                    
                    // 入力方法選択
                    inputMethodSection
                    
                    // 栄養アドバイス
                    nutritionAdviceSection
                }
                .padding()
            }
            .navigationTitle("栄養分析")
            .sheet(isPresented: $showingInputSheet) {
                NutritionInputView(nutritionManager: nutritionManager)
            }
            .sheet(isPresented: $showingPhotoAnalysis) {
                PhotoAnalysisView(nutritionManager: nutritionManager)
            }
        }
    }
    
    private var nutritionSummarySection: some View {
        VStack(spacing: 15) {
            Text("今日の栄養")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                NutritionCard(
                    title: "カロリー",
                    value: "\(Int(nutritionManager.todayCalories))",
                    unit: "kcal",
                    icon: "flame.fill",
                    color: .orange
                )
                
                NutritionCard(
                    title: "タンパク質",
                    value: "\(String(format: "%.1f", nutritionManager.todayProtein))",
                    unit: "g",
                    icon: "dumbbell.fill",
                    color: .green
                )
                
                NutritionCard(
                    title: "炭水化物",
                    value: "\(String(format: "%.1f", nutritionManager.todayCarbs))",
                    unit: "g",
                    icon: "leaf.fill",
                    color: .blue
                )
                
                NutritionCard(
                    title: "脂質",
                    value: "\(String(format: "%.1f", nutritionManager.todayFat))",
                    unit: "g",
                    icon: "drop.fill",
                    color: .yellow
                )
            }
        }
    }
    
    private var nutritionBalanceSection: some View {
        VStack(spacing: 15) {
            Text("栄養素バランス")
                .font(.headline)
            
            // 円グラフ風の表示
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 150, height: 150)
                
                // タンパク質
                Circle()
                    .trim(from: 0, to: proteinPercentage)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                
                // 炭水化物
                Circle()
                    .trim(from: proteinPercentage, to: proteinPercentage + carbsPercentage)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                
                // 脂質
                Circle()
                    .trim(from: proteinPercentage + carbsPercentage, to: 1.0)
                    .stroke(Color.yellow, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("PFC")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("バランス")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 凡例
            HStack(spacing: 20) {
                LegendItem(color: .green, label: "タンパク質", percentage: proteinPercentage)
                LegendItem(color: .blue, label: "炭水化物", percentage: carbsPercentage)
                LegendItem(color: .yellow, label: "脂質", percentage: fatPercentage)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var inputMethodSection: some View {
        VStack(spacing: 15) {
            Text("栄養データ入力")
                .font(.headline)
            
            HStack(spacing: 20) {
                Button(action: {
                    showingInputSheet = true
                }) {
                    VStack {
                        Image(systemName: "pencil")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("手動入力")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                    )
                }
                
                Button(action: {
                    showingPhotoAnalysis = true
                }) {
                    VStack {
                        Image(systemName: "camera")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text("写真分析")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.green.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.green, lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
    
    private var nutritionAdviceSection: some View {
        VStack(spacing: 15) {
            Text("栄養アドバイス")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                NutritionAdviceCard(
                    title: "タンパク質",
                    message: proteinAdvice,
                    color: .green
                )
                
                NutritionAdviceCard(
                    title: "炭水化物",
                    message: carbsAdvice,
                    color: .blue
                )
                
                NutritionAdviceCard(
                    title: "脂質",
                    message: fatAdvice,
                    color: .yellow
                )
            }
        }
    }
    
    // 計算プロパティ
    private var totalCalories: Double {
        return nutritionManager.todayProtein * 4 + nutritionManager.todayCarbs * 4 + nutritionManager.todayFat * 9
    }
    
    private var proteinPercentage: Double {
        guard totalCalories > 0 else { return 0 }
        return (nutritionManager.todayProtein * 4) / totalCalories
    }
    
    private var carbsPercentage: Double {
        guard totalCalories > 0 else { return 0 }
        return (nutritionManager.todayCarbs * 4) / totalCalories
    }
    
    private var fatPercentage: Double {
        guard totalCalories > 0 else { return 0 }
        return (nutritionManager.todayFat * 9) / totalCalories
    }
    
    // アドバイス
    private var proteinAdvice: String {
        if nutritionManager.todayProtein < 60 {
            return "タンパク質が不足しています。鶏肉、魚、卵、豆類を積極的に摂取しましょう。"
        } else if nutritionManager.todayProtein > 120 {
            return "タンパク質の摂取量が多すぎます。適度な量に調整しましょう。"
        } else {
            return "タンパク質の摂取量は適切です。この調子で維持しましょう。"
        }
    }
    
    private var carbsAdvice: String {
        if nutritionManager.todayCarbs < 100 {
            return "炭水化物が不足しています。ご飯、パン、麺類を適度に摂取しましょう。"
        } else if nutritionManager.todayCarbs > 300 {
            return "炭水化物の摂取量が多すぎます。減量中は控えめにしましょう。"
        } else {
            return "炭水化物の摂取量は適切です。"
        }
    }
    
    private var fatAdvice: String {
        if nutritionManager.todayFat < 30 {
            return "脂質が不足しています。良質な油（オリーブオイル、ナッツ類）を摂取しましょう。"
        } else if nutritionManager.todayFat > 80 {
            return "脂質の摂取量が多すぎます。揚げ物や脂っこい料理を控えましょう。"
        } else {
            return "脂質の摂取量は適切です。"
        }
    }
}

struct NutritionCard: View {
    let title: String
    let value: String
    let unit: String
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
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let percentage: Double
    
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            Text(label)
                .font(.caption)
            
            Text("\(Int(percentage * 100))%")
                .font(.caption)
                .fontWeight(.bold)
        }
    }
}

struct NutritionAdviceCard: View {
    let title: String
    let message: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
            }
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct NutritionInputView: View {
    @ObservedObject var nutritionManager: NutritionManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("栄養素を入力")) {
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
                
                Section {
                    Button("保存") {
                        saveNutritionData()
                    }
                    .disabled(calories.isEmpty && protein.isEmpty && carbs.isEmpty && fat.isEmpty)
                }
            }
            .navigationTitle("栄養データ入力")
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
    
    private func saveNutritionData() {
        let caloriesValue = Double(calories) ?? 0
        let proteinValue = Double(protein) ?? 0
        let carbsValue = Double(carbs) ?? 0
        let fatValue = Double(fat) ?? 0
        
        nutritionManager.addNutritionData(
            calories: caloriesValue,
            protein: proteinValue,
            carbs: carbsValue,
            fat: fatValue
        )
        
        dismiss()
    }
}

struct PhotoAnalysisView: View {
    @ObservedObject var nutritionManager: NutritionManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var analysisResult: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(10)
                } else {
                    VStack {
                        Image(systemName: "camera")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("食事の写真を撮影または選択してください")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                if isAnalyzing {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("写真を分析中...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !analysisResult.isEmpty {
                    Text(analysisResult)
                        .font(.body)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                }
                
                HStack(spacing: 20) {
                    Button("写真を選択") {
                        showingImagePicker = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    if selectedImage != nil && !isAnalyzing {
                        Button("分析開始") {
                            analyzePhoto()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("写真分析")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
        }
    }
    
    private func analyzePhoto() {
        isAnalyzing = true
        analysisResult = ""
        
        // 実際のアプリではChatGPT APIを使用して分析
        // ここではダミーの分析結果を表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isAnalyzing = false
            analysisResult = "分析結果:\n• カロリー: 約450kcal\n• タンパク質: 約25g\n• 炭水化物: 約60g\n• 脂質: 約15g\n\nこの結果を記録しますか？"
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
} 