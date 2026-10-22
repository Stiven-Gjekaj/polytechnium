import Foundation
import Testing
@testable import PolyCore

private var calendar: Calendar {
    var calendar = Week.calendar
    calendar.timeZone = TimeZone(identifier: "Europe/Tirane")!
    return calendar
}

private func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
}

private let week = Week(oddMonday: at(26, 0))

private let timetable = Timetable(group: "II-A-ELN", sessions: [
    ClassSession(course: "Matje Elektronike", kind: .lecture, weekday: 3, start: 480, end: 660, room: "204"),
    ClassSession(course: "Automatizim", kind: .lecture, weekday: 3, start: 780, end: 960, room: "206"),
    ClassSession(course: "Elektroteknika 2", kind: .seminar, weekday: 3, start: 1000, end: 1060, room: "110"),
])

@Test func duringAClassTodayGivesItAndTheNextOnes() {
    let today = week.today(in: timetable, at: at(28, 9, 30), calendar: calendar)
    #expect(today.current?.session.course == "Matje Elektronike")
    #expect(today.next?.session.course == "Automatizim")
    #expect(today.later.map(\.session.course) == ["Elektroteknika 2"])
    #expect(abs(today.progress(at: at(28, 9, 30)) - 0.5) < 0.001)
}

@Test func betweenTwoClassesNothingIsOn() {
    let today = week.today(in: timetable, at: at(28, 12), calendar: calendar)
    #expect(today.current == nil)
    #expect(today.next?.session.room == "206")
    #expect(today.progress(at: at(28, 12)) == 0)
}

@Test func afterTheLastClassTheNextIsOnAnotherDay() {
    let today = week.today(in: timetable, at: at(28, 18), calendar: calendar)
    #expect(today.current == nil)
    #expect(today.next?.start == calendar.date(from: DateComponents(year: 2026, month: 11, day: 4, hour: 8)))
    #expect(today.later.isEmpty)
}

@Test func theChangesAreEachStartAndEnd() {
    let changes = week.changes(in: timetable, from: at(28, 7), to: at(28, 23), calendar: calendar)
    #expect(changes == [at(28, 8), at(28, 11), at(28, 13), at(28, 16), at(28, 16, 40), at(28, 17, 40)])
}
