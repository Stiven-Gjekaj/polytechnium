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

