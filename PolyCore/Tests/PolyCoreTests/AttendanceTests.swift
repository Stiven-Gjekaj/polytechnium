import Foundation
import Testing
@testable import PolyCore

private let timetable = Timetable(group: "II-A-ELN", sessions: [
    ClassSession(course: "Elektroteknika 2", kind: .seminar, weekday: 2, start: 840, end: 960),
    ClassSession(course: "Elektroteknika 2", kind: .lab, weekday: 4, start: 600, end: 660, parity: .odd),
    ClassSession(course: "Automatizim", kind: .lecture, weekday: 3, start: 780, end: 960),
])

private func marks(present: Int, absent: Int, course: String = "Elektroteknika 2") -> [AttendanceMark] {
    (0..<present).map { _ in AttendanceMark(course: course, date: .now, kind: .seminar, present: true) }
        + (0..<absent).map { _ in AttendanceMark(course: course, date: .now, kind: .seminar, present: false) }
}

@Test func theSummaryCountsTheMarksOfOneCourse() {
    let all = marks(present: 6, absent: 2) + marks(present: 3, absent: 3, course: "Automatizim")
    let summary = AttendanceSummary(course: "Elektroteknika 2", marks: all, timetable: timetable, weeks: 15, required: 75)
    #expect(summary.present == 6)
    #expect(summary.absent == 2)
    #expect(summary.rate == 0.75)
}

@Test func aClassOfOddWeeksCountsHalf() {
    // One class each week and one in the odd weeks: 1.5 classes a week, 22.5 in 15 weeks.
    let summary = AttendanceSummary(course: "Elektroteknika 2", marks: [], timetable: timetable, weeks: 15, required: 75)
    #expect(summary.planned == 23)
}

@Test func theStudentCanMissAQuarterOfTheClasses() {
    // 25% of 23 classes is 5.75, so 5 classes. Two are missed, so 3 are left.
    let summary = AttendanceSummary(course: "Elektroteknika 2", marks: marks(present: 4, absent: 2), timetable: timetable, weeks: 15, required: 75)
    #expect(summary.canMiss == 3)
}

@Test func missedClassesOverTheLimitGiveANegativeNumber() {
    let summary = AttendanceSummary(course: "Automatizim", marks: marks(present: 1, absent: 5, course: "Automatizim"), timetable: timetable, weeks: 15, required: 80)
    // 20% of 15 classes is 3. Five are missed.
    #expect(summary.canMiss == -2)
}

@Test func noMarksGiveNoRate() {
    #expect(AttendanceSummary(course: "Automatizim", marks: [], timetable: timetable, weeks: 15, required: 75).rate == nil)
}

@Test func theEndedClassesAreTheOnesThatAreOver() {
    var calendar = Week.calendar
    calendar.timeZone = TimeZone(identifier: "Europe/Tirane")!
    let week = Week(oddMonday: calendar.date(from: DateComponents(year: 2026, month: 10, day: 26))!)
    let thursday = calendar.date(from: DateComponents(year: 2026, month: 10, day: 29, hour: 12))!
    #expect(week.ended(in: timetable, on: thursday, calendar: calendar).map(\.session.kind) == [.lab])
}

@Test func theDataGivesTheDefaultRules() {
    let data = AppData(timetable: timetable)
    #expect(data.weeks == 15)
    #expect(data.attendanceSummary(for: "Automatizim").required == 75)
}
