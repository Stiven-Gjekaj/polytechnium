import Foundation

/// A lab report or an assignment with a date and a time of hand-in.
public struct Deadline: Codable, Hashable, Identifiable, Sendable {
    public enum Kind: String, Codable, CaseIterable, Sendable {
        case labReport
        case assignment
        case other
    }

    public var id: UUID
    public var title: String
    public var course: String
    public var kind: Kind
    public var due: Date
    public var done: Bool
    /// Reminders one day and two hours before.
    public var remind: Bool

    public init(
        id: UUID = UUID(), title: String, course: String = "", kind: Kind = .assignment,
        due: Date, done: Bool = false, remind: Bool = true
    ) {
        self.id = id
        self.title = title
        self.course = course
        self.kind = kind
        self.due = due
        self.done = done
        self.remind = remind
    }
}
