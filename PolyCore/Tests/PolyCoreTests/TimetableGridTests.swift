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
