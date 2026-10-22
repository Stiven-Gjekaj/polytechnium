import Foundation
import Testing
@testable import PolyCore

private func temporaryStore() -> DataStore {
    DataStore(url: FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString).appendingPathComponent("data.json"))
}

@Test func aMissingFileGivesEmptyData() throws {
    let data = try temporaryStore().load()
    #expect(data.timetable == nil)
    #expect(data.version == AppData.currentVersion)
}

@Test func savedDataComesBackTheSame() throws {
    let store = temporaryStore()
    let monday = Week.monday(of: Date(timeIntervalSince1970: 1_793_000_000))
    let data = AppData(
        timetable: Timetable(group: "II-A-ELN", sessions: [
            ClassSession(course: "Automatizim", kind: .lecture, weekday: 3, start: 780, end: 960, room: "206", parity: .odd),
        ]),
        week: Week(oddMonday: monday)
    )
    try store.save(data)
    #expect(try store.load() == data)
}

@Test func aFileWithNoVersionReadsAsTheFirstForm() throws {
    let store = temporaryStore()
    try FileManager.default.createDirectory(at: store.url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data(#"{"timetable":{"group":"II-A-ELN","sessions":[]}}"#.utf8).write(to: store.url)
    let data = try store.load()
    #expect(data.version == 1)
    #expect(data.timetable?.group == "II-A-ELN")
}

@Test func aBrokenFileGivesAnError() throws {
    let store = temporaryStore()
    try FileManager.default.createDirectory(at: store.url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data("{".utf8).write(to: store.url)
    #expect(throws: (any Error).self) { try store.load() }
}

@Test func anOldFileMovesInWhenTheStoreHasNone() throws {
    let store = temporaryStore()
    let old = temporaryStore()
    try old.save(AppData(timetable: Timetable(group: "II-A-ELN", sessions: [])))
    store.moveIn(from: old.url)
    #expect(try store.load().timetable?.group == "II-A-ELN")
    #expect(!FileManager.default.fileExists(atPath: old.url.path))
}

@Test func anOldFileDoesNotReplaceANewOne() throws {
    let store = temporaryStore()
    let old = temporaryStore()
    try store.save(AppData(timetable: Timetable(group: "II-B-ELN", sessions: [])))
    try old.save(AppData(timetable: Timetable(group: "II-A-ELN", sessions: [])))
    store.moveIn(from: old.url)
    #expect(try store.load().timetable?.group == "II-B-ELN")
}
