import Foundation
import Testing
@testable import PolyCore

private var calendar: Calendar {
    var calendar = Week.calendar
    calendar.timeZone = TimeZone(identifier: "Europe/Tirane")!
    return calendar
}

private func at(_ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: 2027, month: month, day: day, hour: hour, minute: minute))!
}

private let exam = Exam(course: "Elektroteknika 2", date: at(1, 25, 9), room: "303")

@Test func theDaysLeftCountWholeDays() {
    #expect(exam.daysLeft(from: at(1, 24, 23, 59), calendar: calendar) == 1)
    #expect(exam.daysLeft(from: at(1, 25, 8), calendar: calendar) == 0)
    #expect(exam.daysLeft(from: at(1, 25, 12), calendar: calendar) == 0)
    #expect(exam.daysLeft(from: at(1, 18, 9), calendar: calendar) == 7)
    #expect(exam.daysLeft(from: at(1, 26), calendar: calendar) == -1)
}

@Test func anExamHasRemindersAWeekThreeDaysAndOneDayBefore() {
    let reminders = ReminderPlan.reminders(exams: [exam], after: at(1, 1), calendar: calendar)
    #expect(reminders.map(\.date) == [at(1, 18, 18), at(1, 22, 18), at(1, 24, 18)])
    #expect(reminders.map(\.kind) == [.exam(days: 7), .exam(days: 3), .exam(days: 1)])
    #expect(reminders.allSatisfy { $0.title == "Elektroteknika 2" && $0.place == "303" })
}

@Test func aReminderInThePastIsNotPlanned() {
    let reminders = ReminderPlan.reminders(exams: [exam], after: at(1, 23), calendar: calendar)
    #expect(reminders.map(\.kind) == [.exam(days: 1)])
}

@Test func anExamWithNoRemindersHasNone() {
    var quiet = exam
    quiet.remind = false
    #expect(ReminderPlan.reminders(exams: [quiet], after: at(1, 1), calendar: calendar).isEmpty)
}

@Test func theIdentifierOfAReminderStaysTheSame() {
    let first = ReminderPlan.reminders(exams: [exam], after: at(1, 1), calendar: calendar)
    let second = ReminderPlan.reminders(exams: [exam], after: at(1, 1), calendar: calendar)
    #expect(first.map(\.id) == second.map(\.id))
    #expect(Set(first.map(\.id)).count == 3)
}

@Test func thePlanKeepsTheFirstSixtyReminders() {
    let exams = (0..<30).map { Exam(course: "Course \($0)", date: at(2, 1).addingTimeInterval(Double($0) * 86400)) }
    let reminders = ReminderPlan.reminders(exams: exams, after: at(1, 1), calendar: calendar)
    #expect(reminders.count == ReminderPlan.limit)
    #expect(reminders == reminders.sorted { $0.date < $1.date })
}
