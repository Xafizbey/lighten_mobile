import Foundation

/// Dates and numbers as the student cabinet prints them (apps/web/lib/format.ts).
enum Format {
    private static let ru = Locale(identifier: "ru_RU")
    /// The school's clock (packages/shared/src/calendar.ts).
    static let bishkek = TimeZone(identifier: "Asia/Bishkek")!

    private static let dayParser: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let dayMonth: DateFormatter = {
        let f = DateFormatter()
        f.locale = ru
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "d MMMM"
        return f
    }()

    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    /// "2026-11-16" → "16 ноября". The day is read in UTC so it never shifts.
    static func dayMonth(_ day: String) -> String {
        guard let date = dayParser.date(from: String(day.prefix(10))) else { return day }
        return dayMonth.string(from: date)
    }

    /// A moment as the day it falls on in Bishkek: "16 ноября".
    static func dayMonth(moment: String) -> String {
        guard let date = parseMoment(moment) else { return moment }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = bishkek
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let day = String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
        return dayMonth(day)
    }

    /// ISO 8601 from the API, with or without milliseconds.
    static func parseMoment(_ text: String) -> Date? {
        isoFractional.date(from: text) ?? iso.date(from: text)
    }

    /// Scores: whole numbers without ".0", halves with a comma: "7", "7,5".
    static func score(_ value: Double) -> String {
        if value.rounded() == value { return String(Int(value)) }
        return String(format: "%.1f", value).replacingOccurrences(of: ".", with: ",")
    }

    static func score(_ score: Double, of max: Double) -> String {
        fill(Strings.score, ["score": Format.score(score), "max": Format.score(max)])
    }

    /// Time left in an exam: "12:05" or "1:02:05".
    static func countdown(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%d:%02d", m, sec)
    }

    /// Words in an essay, the way the site counts them (`countWords` in packages/shared).
    static func countWords(_ text: String) -> Int {
        let pattern = "[\\p{L}\\p{N}'’-]+"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }
        let range = NSRange(text.startIndex..., in: text)
        return regex.numberOfMatches(in: text, range: range)
    }
}
