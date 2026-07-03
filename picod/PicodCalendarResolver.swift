import Foundation

struct PicodCalendarResolver {
    let timezoneIdentifier: String
    let dayStartHour: Int
    let eraAnchorDate: Date

    init(
        timezoneIdentifier: String = TimeZone.current.identifier,
        dayStartHour: Int = PicodCalendar.defaultDayStartHour,
        eraAnchorDate: Date = PicodCalendarResolver.defaultEraAnchorDate
    ) {
        self.timezoneIdentifier = timezoneIdentifier
        self.dayStartHour = dayStartHour
        self.eraAnchorDate = eraAnchorDate
    }

    func localDayKey(for date: Date) -> PicodDayKey {
        PicodDayKey(
            rawValue: PicodCalendar.dayKey(
                for: date,
                timezoneIdentifier: timezoneIdentifier,
                dayStartHour: dayStartHour
            )
        )
    }

    func currentLifeID(for date: Date) -> LifeID {
        LifeID(rawValue: "life-\(lifeOrdinal(for: date))")
    }

    func currentCycleID(for date: Date) -> CycleID {
        CycleID(rawValue: "cycle-\(cycleOrdinal(for: date))")
    }

    func currentEraID(for date: Date) -> EraID {
        EraID(rawValue: "era-\(eraOrdinal(for: date))")
    }

    func dayIndexInLife(for date: Date) -> DayIndexInLife {
        DayIndexInLife((elapsedOperationalDays(to: date) % 7) + 1)
    }

    func cycleIndexInEra(for date: Date) -> CycleIndexInEra {
        CycleIndexInEra(((elapsedOperationalDays(to: date) % 49) / 7) + 1)
    }

    func eraDayIndex(for date: Date) -> EraDayIndex {
        EraDayIndex((elapsedOperationalDays(to: date) % 49) + 1)
    }

    func timePosition(for date: Date) -> PicodTimePosition {
        PicodTimePosition(
            localDayKey: localDayKey(for: date),
            lifeID: currentLifeID(for: date),
            cycleID: currentCycleID(for: date),
            eraID: currentEraID(for: date),
            dayIndexInLife: dayIndexInLife(for: date),
            cycleIndexInEra: cycleIndexInEra(for: date),
            eraDayIndex: eraDayIndex(for: date)
        )
    }

    func shouldCloseLife(at date: Date) -> Bool {
        dayIndexInLife(for: date).rawValue == 7 && localHour(for: date) >= 20
    }

    func shouldCloseCycle(at date: Date) -> Bool {
        shouldCloseLife(at: date) && cycleDayOffset(for: date) == 6
    }

    func shouldCloseEra(at date: Date) -> Bool {
        shouldCloseLife(at: date) && eraDayIndex(for: date).rawValue == 49
    }

    private func lifeOrdinal(for date: Date) -> Int {
        (elapsedOperationalDays(to: date) / 7) + 1
    }

    private func cycleOrdinal(for date: Date) -> Int {
        (elapsedOperationalDays(to: date) / 7) + 1
    }

    private func eraOrdinal(for date: Date) -> Int {
        (elapsedOperationalDays(to: date) / 49) + 1
    }

    private func cycleDayOffset(for date: Date) -> Int {
        elapsedOperationalDays(to: date) % 7
    }

    private func elapsedOperationalDays(to date: Date) -> Int {
        let start = PicodCalendar.operationalDayStart(
            for: eraAnchorDate,
            timezoneIdentifier: timezoneIdentifier,
            dayStartHour: dayStartHour
        )
        let end = PicodCalendar.operationalDayStart(
            for: date,
            timezoneIdentifier: timezoneIdentifier,
            dayStartHour: dayStartHour
        )
        return max(
            0,
            PicodCalendar.wholeOperationalDays(
                from: start,
                to: end,
                timezoneIdentifier: timezoneIdentifier
            )
        )
    }

    private func localHour(for date: Date) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timezoneIdentifier) ?? .current
        return calendar.component(.hour, from: date)
    }

    private static var defaultEraAnchorDate: Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = 2026
        components.month = 1
        components.day = 1
        components.hour = 4
        return components.date ?? Date(timeIntervalSince1970: 1_767_247_200)
    }
}
