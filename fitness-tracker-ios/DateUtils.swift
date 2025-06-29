import Foundation

class DateUtil {
    static let shared = DateUtil()
    private let longFormatter: DateFormatter
    private let shortFormatter: DateFormatter
    private let dateTimeFormatter: DateFormatter

    private init() {
        longFormatter = DateFormatter()
        longFormatter.locale = Locale(identifier: "ja_JP")
        longFormatter.dateStyle = .long

        shortFormatter = DateFormatter()
        shortFormatter.locale = Locale(identifier: "ja_JP")
        shortFormatter.dateStyle = .short

        dateTimeFormatter = DateFormatter()
        dateTimeFormatter.locale = Locale(identifier: "ja_JP")
        dateTimeFormatter.dateStyle = .medium
        dateTimeFormatter.timeStyle = .short
    }

    func formatJapaneseDate(_ date: Date) -> String {
        return longFormatter.string(from: date)
    }

    func formatJapaneseDateShort(_ date: Date) -> String {
        return shortFormatter.string(from: date)
    }

    func formatJapaneseDateTime(_ date: Date) -> String {
        return dateTimeFormatter.string(from: date)
    }
} 