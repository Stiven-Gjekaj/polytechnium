import Foundation

/// One class that the student was at, or missed.
public struct AttendanceMark: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var course: String
    public var date: Date
    public var kind: SessionKind
    public var present: Bool

    public init(id: UUID = UUID(), course: String, date: Date, kind: SessionKind, present: Bool) {
        self.id = id
        self.course = course
        self.date = date
        self.kind = kind
        self.present = present
    }
}

/// The attendance of one course so far, and the classes that the student can still miss.
public struct AttendanceSummary: Hashable, Sendable {
    public var present: Int
    public var absent: Int
    /// The classes of the course in the semester, from the timetable.
    public var planned: Int
    /// The part of the classes that the student must be at, in percent.
    public var required: Double

    /// The part of the marked classes that the student was at, from 0 to 1.
    public var rate: Double? {
        present + absent == 0 ? nil : Double(present) / Double(present + absent)
    }

    /// The classes that the student can still miss and keep the required part.
    /// A negative number is the classes that are missed over the limit.
    public var canMiss: Int {
        let allowed = Int((Double(planned) * (100 - required) / 100).rounded(.down))
        return allowed - absent
    }

    /// The default part of the classes that a student must be at.
    public static let defaultRequired: Double = 75

    /// The summary of one course. The semester has `weeks` weeks, and a class of
    /// the odd or the even weeks counts in half of them.
    public init(course: String, marks: [AttendanceMark], timetable: Timetable?, weeks: Int, required: Double) {
        let own = marks.filter { $0.course == course }
        present = own.filter(\.present).count
        absent = own.count - present
        let sessions = (timetable?.sessions ?? []).filter { $0.course == course }
        let perWeek = sessions.map { $0.parity == .every ? 1.0 : 0.5 }.reduce(0, +)
        planned = Int((perWeek * Double(weeks)).rounded())
        self.required = required
    }
}

extension Week {
    /// The classes of a day that are over at `now`, for the question "Were you there?".
    public func ended(in timetable: Timetable, on now: Date, calendar: Calendar = Week.calendar) -> [Occurrence] {
        occurrences(of: timetable, on: now, calendar: calendar).filter { $0.end <= now }
    }
}
