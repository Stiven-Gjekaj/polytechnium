import Foundation

/// One exam of the exam session.
public struct Exam: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var course: String
    /// The day and the time of the start.
    public var date: Date
    public var room: String
    public var note: String
    /// Reminders one week, three days, and one day before.
    public var remind: Bool

    public init(id: UUID = UUID(), course: String, date: Date, room: String = "", note: String = "", remind: Bool = true) {
        self.id = id
        self.course = course
        self.date = date
        self.room = room
        self.note = note
        self.remind = remind
    }

    /// The days from the day of `now` to the day of the exam. 0 is today, and
    /// a negative number is an exam in the past.
    public func daysLeft(from now: Date, calendar: Calendar = Week.calendar) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: date)).day ?? 0
    }
}

/// A local notification that the app asks the system to show.
public struct Reminder: Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        /// An exam in this number of days.
        case exam(days: Int)
        /// A deadline on the next day.
        case deadlineTomorrow
        /// A deadline in this number of hours.
        case deadlineSoon(hours: Int)
    }

    /// The same identifier for the same reminder, so that a new plan replaces the old one.
    public var id: String
    public var date: Date
    public var kind: Kind
    /// The course of an exam, or the title of a deadline.
    public var title: String
    /// The room of an exam, or the course of a deadline.
    public var place: String

    public init(id: String, date: Date, kind: Kind, title: String, place: String) {
        self.id = id
        self.date = date
        self.kind = kind
        self.title = title
        self.place = place
    }
}

public enum ReminderPlan {
    /// The days before an exam with a reminder.
    public static let examDays = [7, 3, 1]
    /// The hour of the reminders of an exam.
    public static let examHour = 18
    /// iOS keeps 64 local notifications of an app. The plan keeps the first ones.
    public static let limit = 60

    /// The reminders of the exams, after `now`, in order.
    public static func reminders(exams: [Exam], deadlines: [Deadline] = [], after now: Date, calendar: Calendar = Week.calendar) -> [Reminder] {
        var result: [Reminder] = []
        for exam in exams where exam.remind {
            let day = calendar.startOfDay(for: exam.date)
            for days in examDays {
                guard let before = calendar.date(byAdding: .day, value: -days, to: day),
                      let date = calendar.date(bySettingHour: examHour, minute: 0, second: 0, of: before)
                else { continue }
                result.append(Reminder(id: "exam-\(exam.id)-\(days)", date: date, kind: .exam(days: days), title: exam.course, place: exam.room))
            }
        }
        for deadline in deadlines where deadline.remind && !deadline.done {
            if let date = calendar.date(byAdding: .day, value: -1, to: deadline.due) {
                result.append(Reminder(id: "deadline-\(deadline.id)-day", date: date, kind: .deadlineTomorrow, title: deadline.title, place: deadline.course))
            }
            let soon = deadline.due.addingTimeInterval(-2 * 3600)
            result.append(Reminder(id: "deadline-\(deadline.id)-soon", date: soon, kind: .deadlineSoon(hours: 2), title: deadline.title, place: deadline.course))
        }
        return Array(result.filter { $0.date > now }.sorted { ($0.date, $0.id) < ($1.date, $1.id) }.prefix(limit))
    }
}
