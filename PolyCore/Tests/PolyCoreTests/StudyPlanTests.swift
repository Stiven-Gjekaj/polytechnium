import Foundation
import Testing
@testable import PolyCore

private var calendar: Calendar {
    var calendar = Week.calendar
    calendar.timeZone = TimeZone(identifier: "Europe/Tirane")!
    return calendar
}

private func day(_ d: Int, _ hour: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: 2027, month: 1, day: d, hour: hour))!
}

private func plan(_ exams: [Exam], done: [StudyDone] = [], now: Date = day(10, 12), perDay: Double = 3, days: Int = 7) -> StudyPlan {
    StudyPlan(exams: exams, done: done, now: now, perDay: perDay, days: days, calendar: calendar)
}

@Test func theHoursSpreadOverTheDaysBeforeTheExam() {
    // 10 hours on the 7 days from 11 to 17 January, for an exam on 18 January.
    let exam = Exam(course: "Elektroteknika 2", date: day(18, 9), studyHours: 10)
    let blocks = plan([exam]).blocks
    #expect(blocks.map(\.hours).reduce(0, +) == 10)
    #expect(blocks.first?.day == day(11))
    #expect(blocks.last?.day == day(17))
    #expect(blocks.allSatisfy { $0.hours <= 2 })
}

@Test func theRevisionStartsTodayWhenTheExamIsNear() {
    let exam = Exam(course: "Automatizim", date: day(13, 9), studyHours: 6)
    let blocks = plan([exam]).blocks
    #expect(blocks.map(\.day) == [day(10), day(11), day(12)])
    #expect(blocks.map(\.hours) == [2, 2, 2])
}

@Test func aDayHasNoMoreThanItsHours() {
    let first = Exam(course: "A", date: day(13, 9), studyHours: 9)
    let second = Exam(course: "B", date: day(14, 9), studyHours: 6)
    let result = plan([first, second])
    for date in [day(10), day(11), day(12), day(13)] {
        #expect(result.blocks(on: date, calendar: calendar).map(\.hours).reduce(0, +) <= 3)
    }
    // The first exam fills 10, 11, and 12 January, so the second gets 13 January only.
    #expect(result.short[second.id] == 3)
    #expect(result.short[first.id] == nil)
}

@Test func theHoursDoneBeforeTodayCount() {
    let exam = Exam(course: "Automatizim", date: day(13, 9), studyHours: 6)
    let done = [StudyDone(exam: exam.id, day: day(9), hours: 3)]
    #expect(plan([exam], done: done).blocks.map(\.hours).reduce(0, +) == 3)
}

@Test func anExamTodayOrInThePastHasNoRevision() {
    let today = Exam(course: "A", date: day(10, 15))
    let past = Exam(course: "B", date: day(5, 9))
    #expect(plan([today, past]).blocks.isEmpty)
}

@Test func anExamWithNoHoursGetsTheDefault() {
    let exam = Exam(course: "A", date: day(30, 9))
    #expect(plan([exam]).blocks.map(\.hours).reduce(0, +) == StudyPlan.defaultHours)
}
