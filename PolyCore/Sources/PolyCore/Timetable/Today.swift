import Foundation

/// What a student needs to know at one moment: the class that is on, the next
/// class, and the other classes of the day.
public struct Today: Hashable, Sendable {
    public var current: Occurrence?
    public var next: Occurrence?
    /// The classes of the day after the next class.
    public var later: [Occurrence]

    public init(current: Occurrence?, next: Occurrence?, later: [Occurrence]) {
        self.current = current
        self.next = next
        self.later = later
    }

    /// The part of the current class that is over, from 0 to 1.
    public func progress(at date: Date) -> Double {
        guard let current else { return 0 }
        let length = current.end.timeIntervalSince(current.start)
        guard length > 0 else { return 1 }
        return min(1, max(0, date.timeIntervalSince(current.start) / length))
    }
}

extension Week {
    /// The current class, the next class, and the other classes of the day.
    public func today(in timetable: Timetable, at date: Date, calendar: Calendar = Week.calendar) -> Today {
        let next = next(in: timetable, after: date, calendar: calendar)
        let day = occurrences(of: timetable, on: date, calendar: calendar)
        let later = next.map { next in day.filter { $0.start >= next.start && $0 != next } } ?? []
        return Today(current: current(in: timetable, at: date, calendar: calendar), next: next, later: later)
    }

    /// Each moment in a time when a class starts or ends, in order. A widget
    /// shows new text at each of these moments.
    public func changes(in timetable: Timetable, from: Date, to: Date, calendar: Calendar = Week.calendar) -> [Date] {
        let moments = occurrences(of: timetable, from: from, to: to, calendar: calendar)
            .flatMap { [$0.start, $0.end] }
            .filter { $0 > from && $0 <= to }
        return Array(Set(moments)).sorted()
    }
}
