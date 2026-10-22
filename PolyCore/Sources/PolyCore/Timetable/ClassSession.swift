import Foundation

/// The kind of a class, from the mark of its cell in the timetable.
public enum SessionKind: String, Codable, CaseIterable, Sendable {
    /// "(L)" in the timetable.
    case lecture
    /// "(S)" in the timetable.
    case seminar
    /// A cell with the word "lab".
    case lab
    /// A cell with no mark, such as a foreign language.
    case other
}

/// The weeks in which a class occurs.
public enum WeekParity: String, Codable, CaseIterable, Sendable {
    case every
    /// "tek" in the timetable: weeks 1, 3, 5, and so on.
    case odd
    /// "cift" in the timetable: weeks 2, 4, 6, and so on.
    case even
}

/// One class in the week.
public struct ClassSession: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var course: String
    public var kind: SessionKind
    /// 1 is Monday and 7 is Sunday.
    public var weekday: Int
    /// Minutes after midnight.
    public var start: Int
    /// Minutes after midnight.
    public var end: Int
    public var room: String
    public var lecturer: String
    public var parity: WeekParity

    public init(
        id: UUID = UUID(),
        course: String,
        kind: SessionKind,
        weekday: Int,
        start: Int,
        end: Int,
        room: String = "",
        lecturer: String = "",
        parity: WeekParity = .every
    ) {
        self.id = id
        self.course = course
        self.kind = kind
        self.weekday = weekday
        self.start = start
        self.end = end
        self.room = room
        self.lecturer = lecturer
        self.parity = parity
    }

    /// The same class with no regard to its identifier.
    func sameClass(as other: ClassSession) -> Bool {
        course == other.course && kind == other.kind && room == other.room
            && lecturer == other.lecturer && parity == other.parity
    }
}

/// The classes of one group, such as "II-A-ELN".
public struct Timetable: Codable, Hashable, Sendable {
    public var group: String
    public var sessions: [ClassSession]

    public init(group: String, sessions: [ClassSession]) {
        self.group = group
        self.sessions = sessions.sorted { ($0.weekday, $0.start, $0.course) < ($1.weekday, $1.start, $1.course) }
    }

    /// The names of the courses, each one time, in the order of the alphabet.
    public var courses: [String] {
        Array(Set(sessions.map(\.course))).sorted()
    }
}
