import Foundation

/// One class on one day, with its real start and end.
public struct Occurrence: Hashable, Identifiable, Sendable {
    public var session: ClassSession
    public var start: Date
    public var end: Date

    public var id: String { "\(session.id)-\(start.timeIntervalSince1970)" }

    public init(session: ClassSession, start: Date, end: Date) {
        self.session = session
        self.start = start
        self.end = end
    }
}

/// The weeks of the semester: which weeks are odd ("tek") and which are even ("cift").
public struct Week: Codable, Hashable, Sendable {
    /// The Monday of a week that is odd.
    public var oddMonday: Date

    public init(oddMonday: Date) {
        self.oddMonday = oddMonday
    }

    /// A calendar of weeks that start on Monday, in the time zone of the device.
    public static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }

    /// The Monday of the week of a day, at midnight.
    public static func monday(of date: Date, calendar: Calendar = Week.calendar) -> Date {
        let start = calendar.startOfDay(for: date)
        let back = (calendar.component(.weekday, from: start) + 5) % 7
        return calendar.date(byAdding: .day, value: -back, to: start) ?? start
    }

    /// 1 for Monday and 7 for Sunday.
    public static func weekday(of date: Date, calendar: Calendar = Week.calendar) -> Int {
        (calendar.component(.weekday, from: date) + 5) % 7 + 1
    }

    /// The parity of the week of a day.
    public func parity(of date: Date, calendar: Calendar = Week.calendar) -> WeekParity {
        let from = Self.monday(of: oddMonday, calendar: calendar)
        let to = Self.monday(of: date, calendar: calendar)
        let days = calendar.dateComponents([.day], from: from, to: to).day ?? 0
        // Round, because a day with a change of the clock is not 24 hours.
        let weeks = Int((Double(days) / 7).rounded(.down))
        return weeks.isMultiple(of: 2) ? .odd : .even
    }

    /// A week with the week of `date` as odd or even.
    public static func with(_ parity: WeekParity, at date: Date, calendar: Calendar = Week.calendar) -> Week {
        let monday = monday(of: date, calendar: calendar)
        let odd = parity == .even ? calendar.date(byAdding: .day, value: -7, to: monday) ?? monday : monday
        return Week(oddMonday: odd)
    }

    /// The classes of one day, in the order of their start.
    public func occurrences(of timetable: Timetable, on date: Date, calendar: Calendar = Week.calendar) -> [Occurrence] {
        let weekday = Self.weekday(of: date, calendar: calendar)
        let parity = parity(of: date, calendar: calendar)
        let midnight = calendar.startOfDay(for: date)
        return timetable.sessions
            .filter { $0.weekday == weekday && ($0.parity == .every || $0.parity == parity) }
            .compactMap { session in
                guard let start = calendar.date(byAdding: .minute, value: session.start, to: midnight),
                      let end = calendar.date(byAdding: .minute, value: session.end, to: midnight)
                else { return nil }
                return Occurrence(session: session, start: start, end: end)
            }
            .sorted { $0.start < $1.start }
    }

    /// The classes from one moment to another, in the order of their start.
    public func occurrences(of timetable: Timetable, from: Date, to: Date, calendar: Calendar = Week.calendar) -> [Occurrence] {
        var result: [Occurrence] = []
        var day = calendar.startOfDay(for: from)
        while day < to {
            result += occurrences(of: timetable, on: day, calendar: calendar).filter { $0.end > from && $0.start < to }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }

    /// The class at a moment, if one is on.
    public func current(in timetable: Timetable, at date: Date, calendar: Calendar = Week.calendar) -> Occurrence? {
        occurrences(of: timetable, on: date, calendar: calendar).first { $0.start <= date && date < $0.end }
    }

    /// The first class that starts after a moment, in the next 14 days.
    public func next(in timetable: Timetable, after date: Date, calendar: Calendar = Week.calendar) -> Occurrence? {
        let end = calendar.date(byAdding: .day, value: 14, to: date) ?? date
        return occurrences(of: timetable, from: date, to: end, calendar: calendar).first { $0.start > date }
    }
}
