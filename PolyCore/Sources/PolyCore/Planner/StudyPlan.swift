import Foundation

/// The study hours that a student did on one day for one exam.
public struct StudyDone: Codable, Hashable, Sendable {
    public var exam: UUID
    /// The day, at midnight.
    public var day: Date
    public var hours: Double

    public init(exam: UUID, day: Date, hours: Double) {
        self.exam = exam
        self.day = day
        self.hours = hours
    }
}

/// The revision for one exam on one day.
public struct StudyBlock: Hashable, Identifiable, Sendable {
    public var exam: UUID
    public var course: String
    /// The day, at midnight.
    public var day: Date
    public var hours: Double

    public var id: String { "\(exam)-\(day.timeIntervalSince1970)" }
}

/// The revision of the exams, spread over the days before each exam.
public struct StudyPlan: Hashable, Sendable {
    public var blocks: [StudyBlock]
    /// The hours of each exam that do not fit in its days.
    public var short: [UUID: Double]

    public static let defaultHours: Double = 10
    public static let defaultHoursPerDay: Double = 3
    public static let defaultDays = 7

    /// The plan from the day of `now`.
    ///
    /// Each exam has its hours, less the hours that the student did before
    /// today. The revision of an exam starts `days` days before it and ends on
    /// the day before it. A day has at most `perDay` hours. The exams that come
    /// first get their hours first, and each exam spreads what is left over its
    /// days, so that no day has all of it.
    public init(
        exams: [Exam], done: [StudyDone], now: Date,
        perDay: Double = StudyPlan.defaultHoursPerDay, days: Int = StudyPlan.defaultDays,
        calendar: Calendar = Week.calendar
    ) {
        let today = calendar.startOfDay(for: now)
        var used: [Date: Double] = [:]
        var blocks: [StudyBlock] = []
        var short: [UUID: Double] = [:]

        for exam in exams.sorted(by: { $0.date < $1.date }) {
            let examDay = calendar.startOfDay(for: exam.date)
            guard examDay > today else { continue }
            let before = done.filter { $0.exam == exam.id && $0.day < today }.map(\.hours).reduce(0, +)
            var remaining = max(0, (exam.studyHours ?? Self.defaultHours) - before)
            let first = max(today, calendar.date(byAdding: .day, value: -days, to: examDay) ?? today)
            var window: [Date] = []
            var day = first
            while day < examDay {
                window.append(day)
                day = calendar.date(byAdding: .day, value: 1, to: day) ?? examDay
            }
            for (index, day) in window.enumerated() where remaining > 0 {
                let share = Self.half(remaining / Double(window.count - index), up: true)
                let give = min(share, perDay - used[day, default: 0], remaining)
                guard give > 0 else { continue }
                used[day, default: 0] += give
                remaining -= give
                blocks.append(StudyBlock(exam: exam.id, course: exam.course, day: day, hours: give))
            }
            // A second pass gives the hours that are left to the days with free time.
            for day in window where remaining > 0 {
                let give = min(perDay - used[day, default: 0], remaining)
                guard give > 0 else { continue }
                used[day, default: 0] += give
                remaining -= give
                if let index = blocks.firstIndex(where: { $0.exam == exam.id && $0.day == day }) {
                    blocks[index].hours += give
                } else {
                    blocks.append(StudyBlock(exam: exam.id, course: exam.course, day: day, hours: give))
                }
            }
            if remaining > 0 { short[exam.id] = remaining }
        }
        self.blocks = blocks.sorted { ($0.day, $0.course) < ($1.day, $1.course) }
        self.short = short
    }

    /// The blocks of one day.
    public func blocks(on day: Date, calendar: Calendar = Week.calendar) -> [StudyBlock] {
        blocks.filter { calendar.isDate($0.day, inSameDayAs: day) }
    }

    /// A number rounded to a half hour.
    static func half(_ value: Double, up: Bool) -> Double {
        up ? (value * 2).rounded(.up) / 2 : (value * 2).rounded(.down) / 2
    }
}
