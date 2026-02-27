import Foundation

// MARK: - Shared DateFormatter (#17, #18)
// DateFormatter is expensive to create. These shared instances avoid per-request allocation.
// All formatters use Asia/Taipei timezone and POSIX locale for consistency.

extension DateFormatter {
    /// Standard date format: "yyyy-MM-dd" in Asia/Taipei timezone
    static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Asia/Taipei")!
        return f
    }()
}

extension Calendar {
    /// Calendar configured for Asia/Taipei timezone
    static let taipei: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Taipei")!
        return cal
    }()
}
