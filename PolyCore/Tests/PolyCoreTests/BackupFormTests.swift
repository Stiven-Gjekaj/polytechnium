import Foundation
import Testing
@testable import PolyCore

@Test func aBackupOfTheOlderFormRestores() throws {
    let older = Data(#"{"version":1,"timetable":{"group":"II-A-ELN","sessions":[]}}"#.utf8)
    let data = try AppData.restore(older)
    #expect(data.timetable?.group == "II-A-ELN")
    #expect(data.version == 2)
}
