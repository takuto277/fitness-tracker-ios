import Foundation
import SwiftUI
import Vision

class NutritionAnalysisManager: ObservableObject {
    @Published var isAnalyzing = false
    @Published var analysisResult: NutritionAnalysisResult?
    @Published var analysisHistory: [NutritionAnalysisResult] = []
    @Published var dailyNutrition: DailyNutrition?
    
    // ChatGPT API設定（実際の実装時に入力）
    private let apiKey = "YOUR_CHATGPT_API_KEY"
    private let apiEndpoint = "https://api.openai.com/v1/chat/completions"
    
    // 今日の栄養摂取量
    @Published var todayCalories: Double = 0
    @Published var todayProtein: Double = 0
    @Published var todayCarbs: Double = 0
    @Published var todayFat: Double = 0
    @Published var todayWater: Double = 0
    
    init() {
        loadAnalysisHistory()
        calculateDailyNutrition()
    }
    
    // 食事写真から栄養分析
    func analyzeMealPhoto(_ image: UIImage) {
        isAnalyzing = true
        
        // 1. 画像をBase64エンコード
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            isAnalyzing = false
            return
        }
        
        let base64Image = imageData.base64EncodedString()
        
        // 2. ChatGPT APIにリクエスト送信
        analyzeWithChatGPT(base64Image: base64Image) { result in
            DispatchQueue.main.async {
                self.isAnalyzing = false
                self.analysisResult = result
                if let result = result {
                    self.addToAnalysisHistory(result)
                    self.updateDailyNutrition(result)
                }
            }
        }
    }
    
    // ChatGPT APIを使用した栄養分析
    private func analyzeWithChatGPT(base64Image: String, completion: @escaping (NutritionAnalysisResult?) -> Void) {
        // リクエストボディの作成
        let requestBody: [String: Any] = [
            "model": "gpt-4-vision-preview",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": """
                            この食事写真を分析して、以下のJSON形式で栄養情報を返してください：
                            {
                                "foods": [
                                    {
                                        "name": "食品名",
                                        "quantity": "量（g）",
                                        "calories": カロリー,
                                        "protein": タンパク質（g）,
                                        "carbs": 炭水化物（g）,
                                        "fat": 脂質（g）
                                    }
                                ],
                                "totalCalories": 総カロリー,
                                "totalProtein": 総タンパク質（g）,
                                "totalCarbs": 総炭水化物（g）,
                                "totalFat": 総脂質（g）,
                                "mealType": "朝食/昼食/夕食/間食",
                                "nutritionAdvice": "栄養アドバイス"
                            }
                            """
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 1000
        ]
        
        // URLRequestの作成
        guard let url = URL(string: apiEndpoint) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(nil)
            return
        }
        
        // APIリクエスト実行
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    let result = self.parseChatGPTResponse(json)
                    completion(result)
                } catch {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }.resume()
    }
    
    // ChatGPT APIレスポンスの解析
    private func parseChatGPTResponse(_ json: [String: Any]?) -> NutritionAnalysisResult? {
        guard let json = json,
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            return nil
        }
        
        // JSON文字列からNutritionAnalysisResultを作成
        return parseNutritionJSON(content)
    }
    
    // 栄養情報JSONの解析
    private func parseNutritionJSON(_ jsonString: String) -> NutritionAnalysisResult? {
        // JSON文字列からNutritionAnalysisResultオブジェクトを作成
        // 実際の実装では、より詳細なJSON解析が必要
        
        // 仮の実装（実際のAPIレスポンスに合わせて調整）
        let foods = [
            FoodItem(name: "サンプル食品", quantity: "100g", calories: 200, protein: 10, carbs: 30, fat: 5)
        ]
        
        return NutritionAnalysisResult(
            id: UUID(),
            timestamp: Date(),
            foods: foods,
            totalCalories: 200,
            totalProtein: 10,
            totalCarbs: 30,
            totalFat: 5,
            mealType: .lunch,
            nutritionAdvice: "バランスの良い食事です。タンパク質をもう少し増やすと良いでしょう。"
        )
    }
    
    // 分析履歴に追加
    private func addToAnalysisHistory(_ result: NutritionAnalysisResult) {
        analysisHistory.append(result)
        saveAnalysisHistory()
    }
    
    // 分析履歴の保存
    private func saveAnalysisHistory() {
        // UserDefaultsまたはCore Dataに保存
        // 実際の実装では永続化が必要
    }
    
    // 分析履歴の読み込み
    private func loadAnalysisHistory() {
        // UserDefaultsまたはCore Dataから読み込み
        // 実際の実装では永続化が必要
    }
    
    // 日次栄養摂取量の更新
    private func updateDailyNutrition(_ result: NutritionAnalysisResult) {
        todayCalories += result.totalCalories
        todayProtein += result.totalProtein
        todayCarbs += result.totalCarbs
        todayFat += result.totalFat
        
        calculateDailyNutrition()
    }
    
    // 日次栄養摂取量の計算
    private func calculateDailyNutrition() {
        dailyNutrition = DailyNutrition(
            date: Date(),
            calories: todayCalories,
            protein: todayProtein,
            carbs: todayCarbs,
            fat: todayFat,
            water: todayWater
        )
    }
    
    // 栄養目標との比較
    func getNutritionProgress() -> NutritionProgress {
        let targetCalories: Double = 2000 // 個人の目標に応じて調整
        let targetProtein: Double = 120 // 体重1kgあたり1.6g
        let targetCarbs: Double = 250 // 総カロリーの50%
        let targetFat: Double = 67 // 総カロリーの30%
        let targetWater: Double = 2000 // ml
        
        return NutritionProgress(
            caloriesProgress: min(todayCalories / targetCalories, 1.0),
            proteinProgress: min(todayProtein / targetProtein, 1.0),
            carbsProgress: min(todayCarbs / targetCarbs, 1.0),
            fatProgress: min(todayFat / targetFat, 1.0),
            waterProgress: min(todayWater / targetWater, 1.0)
        )
    }
    
    // 栄養アドバイスの取得
    func getNutritionAdvice() -> String {
        let progress = getNutritionProgress()
        
        var advice = "今日の栄養摂取状況:\n"
        
        if progress.caloriesProgress < 0.8 {
            advice += "• カロリーが不足しています。適切な食事を心がけましょう。\n"
        } else if progress.caloriesProgress > 1.2 {
            advice += "• カロリーオーバーです。運動量を増やすか食事を見直しましょう。\n"
        }
        
        if progress.proteinProgress < 0.8 {
            advice += "• タンパク質が不足しています。筋肉維持のためにもう少し摂取しましょう。\n"
        }
        
        if progress.waterProgress < 0.8 {
            advice += "• 水分が不足しています。こまめに水分補給しましょう。\n"
        }
        
        return advice
    }
    
    // 手動で栄養情報を追加
    func addManualNutrition(calories: Double, protein: Double, carbs: Double, fat: Double) {
        todayCalories += calories
        todayProtein += protein
        todayCarbs += carbs
        todayFat += fat
        
        calculateDailyNutrition()
    }
    
    // 水分摂取を記録
    func addWaterIntake(amount: Double) {
        todayWater += amount
        calculateDailyNutrition()
    }
    
    // 日次データのリセット
    func resetDailyNutrition() {
        todayCalories = 0
        todayProtein = 0
        todayCarbs = 0
        todayFat = 0
        todayWater = 0
        calculateDailyNutrition()
    }
}

// データ構造
struct NutritionAnalysisResult: Identifiable {
    let id: UUID
    let timestamp: Date
    let foods: [FoodItem]
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let mealType: MealType
    let nutritionAdvice: String
}

struct FoodItem {
    let name: String
    let quantity: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}

enum MealType: String, CaseIterable {
    case breakfast = "朝食"
    case lunch = "昼食"
    case dinner = "夕食"
    case snack = "間食"
}

struct DailyNutrition {
    let date: Date
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let water: Double
}

struct NutritionProgress {
    let caloriesProgress: Double
    let proteinProgress: Double
    let carbsProgress: Double
    let fatProgress: Double
    let waterProgress: Double
} 