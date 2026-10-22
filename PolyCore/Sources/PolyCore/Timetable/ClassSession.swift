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
    ///
    /// The timetable sometimes writes one course in two forms, such as
    /// "Analiza Numerike" and "Analize Numerike". Two names with the same numbers
    /// and no more than one other letter are one course, and the first name in
    /// the alphabet stays.
    public var courses: [String] {
        var names: [String] = []
        for name in Array(Set(sessions.map(\.course))).sorted()
        where !names.contains(where: { Self.isSameCourse($0, name) }) {
            names.append(name)
        }
        return names
    }

    /// True for two names of one course with no more than one other letter.
    public static func isSameCourse(_ a: String, _ b: String) -> Bool {
        let x = Array(CellText.fold(a)), y = Array(CellText.fold(b))
        // "Fizika 1" and "Fizika 2" are two courses.
        guard x.filter(\.isNumber) == y.filter(\.isNumber) else { return false }
        guard min(x.count, y.count) >= 8, abs(x.count - y.count) <= 1 else { return x == y }
        // The edit distance, with a stop after two changes.
        var previous = Array(0...y.count)
        for i in 1...x.count {
            var current = [i] + Array(repeating: 0, count: y.count)
            for j in 1...y.count {
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + (x[i - 1] == y[j - 1] ? 0 : 1))
            }
            if current.min()! > 1 { return false }
            previous = current
        }
        return previous[y.count] <= 1
    }
}
