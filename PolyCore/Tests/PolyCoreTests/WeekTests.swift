import Foundation
import Testing
@testable import PolyCore

private var calendar: Calendar {
    var calendar = Week.calendar
    calendar.timeZone = TimeZone(identifier: "Europe/Tirane")!
    return calendar
}

private func day(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

/// Monday 26 October 2026 is in an odd week in each test.
private let week = Week(oddMonday: day(2026, 10, 26))

private let timetable = Timetable(group: "II-A-ELN", sessions: [
    ClassSession(course: "Analiza Numerike", kind: .seminar, weekday: 1, start: 480, end: 540, room: "111"),
    ClassSession(course: "Teoria e Sinjaleve", kind: .lecture, weekday: 1, start: 960, end: 1140, room: "303"),
    ClassSession(course: "Teori Sinjali", kind: .seminar, weekday: 2, start: 960, end: 1020, room: "110", parity: .odd),
    ClassSession(course: "Teori Sinjali", kind: .seminar, weekday: 2, start: 960, end: 1020, room: "201", parity: .even),
])

@Test func theMondayOfADayIsAtMidnight() {
    #expect(Week.monday(of: day(2026, 10, 29, 15), calendar: calendar) == day(2026, 10, 26))
    #expect(Week.monday(of: day(2026, 11, 1, 23), calendar: calendar) == day(2026, 10, 26))
    #expect(Week.weekday(of: day(2026, 11, 1), calendar: calendar) == 7)
}

@Test func theWeeksAreOddAndEvenInTurn() {
    #expect(week.parity(of: day(2026, 10, 28), calendar: calendar) == .odd)
    #expect(week.parity(of: day(2026, 11, 2), calendar: calendar) == .even)
    #expect(week.parity(of: day(2026, 11, 9), calendar: calendar) == .odd)
    #expect(week.parity(of: day(2026, 10, 19), calendar: calendar) == .even)
}

@Test func theParityStaysOverTheChangeOfTheClock() {
    // The clocks of Albania go back on 25 October 2026.
    let odd = Week(oddMonday: day(2026, 10, 19))
    #expect(odd.parity(of: day(2026, 10, 26, 9), calendar: calendar) == .even)
    #expect(odd.parity(of: day(2027, 3, 29, 9), calendar: calendar) == .even)
}

@Test func aWeekSetFromTodayGivesThatParity() {
    let even = Week.with(.even, at: day(2026, 11, 4), calendar: calendar)
    #expect(even.parity(of: day(2026, 11, 4), calendar: calendar) == .even)
    #expect(even.parity(of: day(2026, 11, 11), calendar: calendar) == .odd)
}

@Test func aDayHasOnlyTheClassesOfItsWeek() {
    let odd = week.occurrences(of: timetable, on: day(2026, 10, 27), calendar: calendar)
    #expect(odd.map(\.session.room) == ["110"])
    let even = week.occurrences(of: timetable, on: day(2026, 11, 3), calendar: calendar)
    #expect(even.map(\.session.room) == ["201"])
    #expect(odd.first?.start == day(2026, 10, 27, 16))
}

@Test func theCurrentClassIsTheOneThatIsOn() {
    #expect(week.current(in: timetable, at: day(2026, 10, 26, 8, 30), calendar: calendar)?.session.course == "Analiza Numerike")
    #expect(week.current(in: timetable, at: day(2026, 10, 26, 9), calendar: calendar) == nil)
}

@Test func theNextClassCanBeOnAnotherDay() {
    let next = week.next(in: timetable, after: day(2026, 10, 26, 19), calendar: calendar)
    #expect(next?.session.room == "110")
    #expect(next?.start == day(2026, 10, 27, 16))
    let sunday = week.next(in: timetable, after: day(2026, 11, 1, 12), calendar: calendar)
    #expect(sunday?.start == day(2026, 11, 2, 8))
}

@Test func anEmptyTimetableHasNoNextClass() {
    #expect(week.next(in: Timetable(group: "", sessions: []), after: day(2026, 10, 26), calendar: calendar) == nil)
}
