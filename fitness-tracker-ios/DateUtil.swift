import Foundation

class DateUtil {
    static let shared = DateUtil()
    
    private let dateFormatter = DateFormatter()
    private let calendar = Calendar.current
    
    private init() {
        dateFormatter.locale = Locale(identifier: "ja_JP")
    }
    
    func formatJapaneseDate(_ date: Date, format: String = "yyyy年MM月dd日") -> String {
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
    
    func formatJapaneseDateWithWeekday(_ date: Date) -> String {
        dateFormatter.dateFormat = "yyyy年MM月dd日 (E)"
        return dateFormatter.string(from: date)
    }
    
    func formatTime(_ date: Date) -> String {
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: date)
    }
    
    func formatDateTime(_ date: Date) -> String {
        dateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return dateFormatter.string(from: date)
    }
    
    func getWeekdayString(_ date: Date) -> String {
        dateFormatter.dateFormat = "E"
        return dateFormatter.string(from: date)
    }
    
    func getMonthString(_ date: Date) -> String {
        dateFormatter.dateFormat = "M月"
        return dateFormatter.string(from: date)
    }
    
    func getYearMonthString(_ date: Date) -> String {
        dateFormatter.dateFormat = "yyyy年M月"
        return dateFormatter.string(from: date)
    }
    
    func isToday(_ date: Date) -> Bool {
        return calendar.isDateInToday(date)
    }
    
    func isYesterday(_ date: Date) -> Bool {
        return calendar.isDateInYesterday(date)
    }
    
    func isThisWeek(_ date: Date) -> Bool {
        return calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    func isThisMonth(_ date: Date) -> Bool {
        return calendar.isDate(date, equalTo: Date(), toGranularity: .month)
    }
    
    func getStartOfWeek(_ date: Date) -> Date {
        return calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
    }
    
    func getEndOfWeek(_ date: Date) -> Date {
        return calendar.dateInterval(of: .weekOfYear, for: date)?.end ?? date
    }
    
    func getStartOfMonth(_ date: Date) -> Date {
        return calendar.dateInterval(of: .month, for: date)?.start ?? date
    }
    
    func getEndOfMonth(_ date: Date) -> Date {
        return calendar.dateInterval(of: .month, for: date)?.end ?? date
    }
    
    func getDaysInMonth(_ date: Date) -> Int {
        return calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }
    
    func getWeekdayNumber(_ date: Date) -> Int {
        return calendar.component(.weekday, from: date)
    }
    
    func addDays(_ date: Date, days: Int) -> Date {
        return calendar.date(byAdding: .day, value: days, to: date) ?? date
    }
    
    func addWeeks(_ date: Date, weeks: Int) -> Date {
        return calendar.date(byAdding: .weekOfYear, value: weeks, to: date) ?? date
    }
    
    func addMonths(_ date: Date, months: Int) -> Date {
        return calendar.date(byAdding: .month, value: months, to: date) ?? date
    }
    
    func getDaysBetween(_ startDate: Date, _ endDate: Date) -> Int {
        return calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    func getWeeksBetween(_ startDate: Date, _ endDate: Date) -> Int {
        return calendar.dateComponents([.weekOfYear], from: startDate, to: endDate).weekOfYear ?? 0
    }
    
    func getMonthsBetween(_ startDate: Date, _ endDate: Date) -> Int {
        return calendar.dateComponents([.month], from: startDate, to: endDate).month ?? 0
    }
    
    func getRelativeDateString(_ date: Date) -> String {
        if isToday(date) {
            return "今日"
        } else if isYesterday(date) {
            return "昨日"
        } else {
            let days = getDaysBetween(date, Date())
            if days > 0 {
                return "\(days)日前"
            } else {
                return "\(abs(days))日後"
            }
        }
    }
    
    func getAge(from birthDate: Date) -> Int {
        return calendar.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }
    
    func getJapaneseEra(_ date: Date) -> String {
        let year = calendar.component(.year, from: date)
        if year >= 2019 {
            return "令和\(year - 2018)"
        } else if year >= 1989 {
            return "平成\(year - 1988)"
        } else if year >= 1926 {
            return "昭和\(year - 1925)"
        } else {
            return "大正\(year - 1911)"
        }
    }
} 