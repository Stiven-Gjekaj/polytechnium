import Foundation
import Testing
@testable import PolyCore

private var calendar: Calendar {
    var calendar = Week.calendar
    calendar.timeZone = TimeZone(identifier: "Europe/Tirane")!
    return calendar
}

private func at(_ day: Int, _ hour: Int) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
}

private func data() -> AppData {
    var data = AppData(
        timetable: Timetable(group: "II-A-ELN", sessions: [
            ClassSession(course: "Matje Elektronike", kind: .lecture, weekday: 3, start: 480, end: 660),
            ClassSession(course: "Automatizim", kind: .lecture, weekday: 3, start: 780, end: 960),
        ]),
        week: Week(oddMonday: at(26, 0))
    )
    data.attendance = []
    return data
}

@Test func theClassesThatAreOverAndHaveNoMarkAreAsked() {
    var data = data()
    #expect(data.unmarked(on: at(28, 17), calendar: calendar).map(\.session.course) == ["Matje Elektronike", "Automatizim"])
    data.attendance.append(AttendanceMark(course: "Matje Elektronike", date: at(28, 8), kind: .lecture, present: true))
    #expect(data.unmarked(on: at(28, 17), calendar: calendar).map(\.session.course) == ["Automatizim"])
    // A mark of another day does not count.
    data.attendance = [AttendanceMark(course: "Automatizim", date: at(21, 13), kind: .lecture, present: true)]
    #expect(data.unmarked(on: at(28, 12), calendar: calendar).map(\.session.course) == ["Matje Elektronike"])
}

@Test func eachDayOfRevisionHasAReminder() {
    let exam = Exam(course: "Automatizim", date: at(30, 9), studyHours: 4)
    let plan = StudyPlan(exams: [exam], done: [], now: at(27, 8), perDay: 3, days: 7, calendar: calendar)
    let reminders = ReminderPlan.reminders(exams: [], study: plan, after: at(27, 8), calendar: calendar)
    #expect(reminders.map(\.date) == [at(27, 17), at(28, 17), at(29, 17)])
    #expect(reminders.map(\.kind).reduce(0.0) { sum, kind in
        if case let .study(hours) = kind { return sum + hours } else { return sum }
    } == 4)
}
