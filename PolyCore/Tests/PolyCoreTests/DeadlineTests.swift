import Foundation
import Testing
@testable import PolyCore

private var calendar: Calendar {
    var calendar = Week.calendar
    calendar.timeZone = TimeZone(identifier: "Europe/Tirane")!
    return calendar
}

private func at(_ day: Int, _ hour: Int) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour))!
}

private let report = Deadline(title: "Lab report 3", course: "Elektroteknika 2", kind: .labReport, due: at(12, 23))

@Test func aDeadlineHasRemindersOneDayAndTwoHoursBefore() {
    let reminders = ReminderPlan.reminders(exams: [], deadlines: [report], after: at(1, 0), calendar: calendar)
    #expect(reminders.map(\.date) == [at(11, 23), at(12, 21)])
    #expect(reminders.map(\.kind) == [.deadlineTomorrow, .deadlineSoon(hours: 2)])
    #expect(reminders.allSatisfy { $0.title == "Lab report 3" && $0.place == "Elektroteknika 2" })
}

@Test func aDoneDeadlineHasNoReminders() {
    var done = report
    done.done = true
    #expect(ReminderPlan.reminders(exams: [], deadlines: [done], after: at(1, 0), calendar: calendar).isEmpty)
}

@Test func theRemindersOfExamsAndDeadlinesAreInOneOrder() {
    let exam = Exam(course: "Automatizim", date: at(14, 9))
    let reminders = ReminderPlan.reminders(exams: [exam], deadlines: [report], after: at(10, 0), calendar: calendar)
    // 11 November at 18:00 and at 23:00, 12 November at 21:00, and 13 November at 18:00.
    #expect(reminders.map(\.kind) == [.exam(days: 3), .deadlineTomorrow, .deadlineSoon(hours: 2), .exam(days: 1)])
}
