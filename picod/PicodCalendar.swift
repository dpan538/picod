import Foundation

enum PicodCalendar {
    static let defaultDayStartHour = 4

    static func dayKey(
        for date: Date,
        timezoneIdentifier: String,
        dayStartHour: Int = defaultDayStartHour
    ) -> String {
        let calendar = gregorianCalendar(timezoneIdentifier: timezoneIdentifier)
        let shifted = calendar.date(byAdding: .hour, value: -dayStartHour, to: date) ?? date
        let comps = calendar.dateComponents([.year, .month, .day], from: shifted)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
    }

    static func operationalDayStart(
        for date: Date,
        timezoneIdentifier: String,
        dayStartHour: Int = defaultDayStartHour
    ) -> Date {
        let calendar = gregorianCalendar(timezoneIdentifier: timezoneIdentifier)
        let shifted = calendar.date(byAdding: .hour, value: -dayStartHour, to: date) ?? date
        let shiftedStart = calendar.startOfDay(for: shifted)
        return calendar.date(byAdding: .hour, value: dayStartHour, to: shiftedStart) ?? shiftedStart
    }

    static func addingOperationalDays(
        _ days: Int,
        to dayStart: Date,
        timezoneIdentifier: String
    ) -> Date {
        let calendar = gregorianCalendar(timezoneIdentifier: timezoneIdentifier)
        return calendar.date(byAdding: .day, value: days, to: dayStart) ?? dayStart
    }

    static func wholeOperationalDays(
        from start: Date,
        to end: Date,
        timezoneIdentifier: String
    ) -> Int {
        let calendar = gregorianCalendar(timezoneIdentifier: timezoneIdentifier)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    private static func gregorianCalendar(timezoneIdentifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        if let timezone = TimeZone(identifier: timezoneIdentifier) {
            calendar.timeZone = timezone
        }
        return calendar
    }
}
