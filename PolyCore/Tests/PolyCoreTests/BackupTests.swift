import Foundation
import Testing
@testable import PolyCore

@Test func aBackupComesBackTheSame() throws {
    let data = AppData(
        timetable: Timetable(group: "II-A-ELN", sessions: [
            ClassSession(course: "Automatizim", kind: .lecture, weekday: 3, start: 780, end: 960, room: "206"),
        ]),
        courses: [CourseGrade(name: "Automatizim", credits: 6, finalGrade: 9)]
    )
    #expect(try AppData.restore(data.backup()) == data)
}

@Test func aFileThatIsNotABackupFails() {
    #expect(throws: AppData.BackupFailure.notABackup) { try AppData.restore(Data("[1, 2]".utf8)) }
    #expect(throws: AppData.BackupFailure.notABackup) { try AppData.restore(Data("{\"name\": \"x\"}".utf8)) }
    #expect(throws: AppData.BackupFailure.notABackup) { try AppData.restore(Data("{\"version\": 1, \"courses\": 3}".utf8)) }
}

@Test func aBackupOfANewerFormFails() {
    let newer = Data("{\"version\": \(AppData.currentVersion + 1)}".utf8)
    #expect(throws: AppData.BackupFailure.tooNew(version: AppData.currentVersion + 1)) { try AppData.restore(newer) }
}

@Test func aNewerVersionIsFound() {
    #expect(AppVersion.isNewer("v1.0.0", than: "0.6.0"))
    #expect(AppVersion.isNewer("0.10.0", than: "0.9.1"))
    #expect(AppVersion.isNewer("1.0.1", than: "1.0"))
    #expect(!AppVersion.isNewer("v1.0.0", than: "1.0.0"))
    #expect(!AppVersion.isNewer("0.9.0", than: "1.0.0"))
}
