import Testing
@testable import PolyCore

private func timetable(_ names: [String]) -> Timetable {
    Timetable(group: "II-A-ELN", sessions: names.map {
        ClassSession(course: $0, kind: .seminar, weekday: 1, start: 480, end: 540)
    })
}

@Test func theCoursesAreEachOneTimeInOrder() {
    #expect(timetable(["Automatizim", "Analiza Numerike", "Automatizim"]).courses == ["Analiza Numerike", "Automatizim"])
}

@Test func twoFormsOfOneCourseAreOneCourse() {
    #expect(timetable(["Analize Numerike", "Analiza Numerike"]).courses == ["Analiza Numerike"])
    #expect(timetable(["Elementet e Elektronikes", "Elementet e elektronikes"]).courses == ["Elementet e Elektronikes"])
}

@Test func twoCoursesWithOneOtherNumberStayTwo() {
    #expect(timetable(["Fizika 1", "Fizika 2"]).courses == ["Fizika 1", "Fizika 2"])
    #expect(timetable(["Elektroteknika 2", "Elektroteknika 3"]).courses.count == 2)
}

@Test func twoDifferentCoursesStayTwo() {
    #expect(timetable(["Teori Sinjali", "Teoria e Sinjaleve"]).courses.count == 2)
}
