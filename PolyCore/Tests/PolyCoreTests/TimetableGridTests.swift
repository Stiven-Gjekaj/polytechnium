import Foundation
import Testing
@testable import PolyCore

/// The classes of the small timetable that each test reads.
private let drawing = TimetableDrawing(classes: [
    .init(columns: 1...1, rows: 0...0, text: "(S) Analiza Numerike R. Datja 111"),
    .init(columns: 2...3, rows: 0...1, text: "(L) Teoria e Sinjaleve B. Kamo 303"),
    .init(columns: 1...1, rows: 2...2, text: "(S) Teori Sinjali E. Omari 110 tek (S) Teori Sinjali E. Omari 201 cift"),
    .init(columns: 3...3, rows: 4...4, text: "(S) Elektroteknika 2 L. Gjini lab 110"),
    .init(columns: 3...3, rows: 5...5, text: "(S) Elektroteknika 2 L. Gjini lab 110"),
])

private func expectTheClasses(of grid: TimetableGrid) {
    #expect(grid.groups == ["II-A-ELN", "II-B-ELN", "II-C-ELN"])

    let a = grid.timetable(for: "II-A-ELN").sessions
    #expect(a.count == 3)
    #expect(a.first { $0.course == "Analiza Numerike" }.map { [$0.weekday, $0.start, $0.end] } == [1, 480, 540])
    let odd = a.first { $0.parity == .odd }
    let even = a.first { $0.parity == .even }
    #expect(odd?.room == "110")
    #expect(even?.room == "201")
    #expect(odd?.start == 600)

    // A merged cell gives the lecture to both groups, for both hours.
    for group in ["II-B-ELN", "II-C-ELN"] {
        let lecture = grid.timetable(for: group).sessions.first { $0.kind == .lecture }
        #expect(lecture?.course == "Teoria e Sinjaleve")
        #expect(lecture?.lecturer == "B. Kamo")
        #expect(lecture.map { [$0.weekday, $0.start, $0.end] } == [1, 480, 600])
    }

    // The two hours of the lab on Tuesday become one class.
    let lab = grid.timetable(for: "II-C-ELN").sessions.first { $0.kind == .lab }
    #expect(lab.map { [$0.weekday, $0.start, $0.end] } == [2, 480, 600])
    #expect(grid.timetable(for: "II-B-ELN").sessions.count == 1)
}

@Test func theGridReadsTheCellsFromTheBorders() {
    expectTheClasses(of: TimetableGrid(rects: drawing.borders, glyphs: drawing.glyphs))
}

@Test func aPDFOfTheTimetableGivesTheSameClasses() throws {
    expectTheClasses(of: try TimetablePDF.read(drawing.pdf))
}

@Test func dataThatIsNotAPDFFails() {
    #expect(throws: TimetablePDF.Failure.notAPDF) { try TimetablePDF.read(Data("timetable".utf8)) }
}

@Test func aPDFWithNoTimetableFails() {
    let empty = TimetableDrawing(classes: [])
    #expect(throws: TimetablePDF.Failure.noTimetable) { try TimetablePDF.read(empty.pdf) }
}

/// The real timetable of the faculty, when a copy is in `private/`. The file is
/// not in the repository, so the test does nothing on another machine.
@Test func theRealTimetableGivesTheClassesOfELN2A() throws {
    let url = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("private/Orari-Bachelor-4.pdf")
    guard let data = try? Data(contentsOf: url) else { return }
    let grid = try TimetablePDF.read(data)
    #expect(grid.groups.contains("II-A-ELN"))
    let classes = grid.timetable(for: "II-A-ELN").sessions
    let monday = classes.filter { $0.weekday == 1 }
    #expect(monday.map(\.course) == ["Analiza Numerike", "Teoria e Sinjaleve"])
    #expect(monday.last.map { [$0.start, $0.end] } == [960, 1140])
    let wednesday = classes.first { $0.weekday == 3 && $0.course == "Matje Elektronike" }
    #expect(wednesday.map { [$0.start, $0.end] } == [480, 660])
    #expect(wednesday?.room == "204")
    #expect(wednesday?.lecturer == "A. Lala")
}
