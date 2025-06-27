import Foundation

// 日本語日付フォーマット関数
func formatJapaneseDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ja_JP")
    formatter.dateStyle = .long
    return formatter.string(from: date)
}

// 短縮版の日本語日付フォーマット
func formatJapaneseDateShort(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ja_JP")
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}

// 時間付きの日本語日付フォーマット
func formatJapaneseDateTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ja_JP")
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
} 