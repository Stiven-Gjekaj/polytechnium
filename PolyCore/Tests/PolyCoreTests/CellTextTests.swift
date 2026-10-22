import Testing
@testable import PolyCore

@Test func aSeminarGivesItsCourseLecturerAndRoom() throws {
    let cell = try #require(CellText("(S) Analiza Numerike R. Datja 111"))
    #expect(cell.kind == .seminar)
    #expect(cell.course == "Analiza Numerike")
    #expect(cell.lecturer == "R. Datja")
    #expect(cell.room == "111")
    #expect(cell.parity == .every)
}

@Test func aLectureWithOddWeeksGivesTheParity() throws {
    let cell = try #require(CellText("(L) Automatizim M. Gjonaj 303 tek"))
    #expect(cell.kind == .lecture)
    #expect(cell.course == "Automatizim")
    #expect(cell.room == "303")
    #expect(cell.parity == .odd)
}

@Test func evenWeeksReadWithAndWithNoCedilla() throws {
    #expect(CellText("(S) Teori Sinjali I. Shinko 206 çift")?.parity == .even)
    #expect(CellText("(S) Teori Sinjali I. Shinko 206 cift")?.parity == .even)
}

@Test func aNameWithNoSpaceAfterTheInitialGetsOne() throws {
    let cell = try #require(CellText("(S) Teori Sinjali L.Likaj 108 cift"))
    #expect(cell.course == "Teori Sinjali")
    #expect(cell.lecturer == "L. Likaj")
    #expect(cell.room == "108")
}

@Test func aNumberInTheCourseNameStaysInTheName() throws {
    let cell = try #require(CellText("(S) Elektroteknika 2 L. Dhamo 115"))
    #expect(cell.course == "Elektroteknika 2")
    #expect(cell.lecturer == "L. Dhamo")
}

@Test func twoRoomsJoinWithAComma() throws {
    #expect(CellText("(S) Analiza Numerike R. Datja 109 302")?.room == "109, 302")
}

@Test func aRoomWrittenTwoTimesGivesOneRoom() throws {
    #expect(CellText("(S)Sinjale dhe sisteme 115115")?.room == "115")
    #expect(CellText("(S)Sinjale dhe sisteme 115115")?.course == "Sinjale dhe sisteme")
}

@Test func theWordLabMakesALab() throws {
    let cell = try #require(CellText("(S) Elektronika Analoge D.Shahu lab cift 111"))
    #expect(cell.kind == .lab)
    #expect(cell.lecturer == "D. Shahu")
    #expect(cell.parity == .even)
}

@Test func labBeforeANumberIsARoom() throws {
    let cell = try #require(CellText("Gjuhe e huaj 3 LAB 108"))
    #expect(cell.kind == .other)
    #expect(cell.course == "Gjuhe e huaj 3")
    #expect(cell.room == "LAB 108")
}

@Test func aCellWithNoCourseGivesNil() {
    #expect(CellText("(S) 111") == nil)
    #expect(CellText("   ") == nil)
}
