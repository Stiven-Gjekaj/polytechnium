import Foundation
import Testing
@testable import PolyCore

@Test func anAddressWithNoSchemeGetsHttps() {
    #expect(CourseLink.webAddress("moodle.upt.al/course/view.php?id=12")?.absoluteString == "https://moodle.upt.al/course/view.php?id=12")
    #expect(CourseLink.webAddress("  http://fti.edu.al  ")?.absoluteString == "http://fti.edu.al")
}

@Test func aTextThatIsNotAnAddressGivesNil() {
    #expect(CourseLink.webAddress("") == nil)
    #expect(CourseLink.webAddress("lab sheet") == nil)
    #expect(CourseLink.webAddress("notes") == nil)
    #expect(CourseLink.webAddress("ftp://files.upt.al/a.pdf") == nil)
}

@Test func aStoredFileKeepsItsExtension() {
    let id = UUID(uuidString: "6F9619FF-8B86-D011-B42D-00C04FC964FF")!
    #expect(CourseLink.storedName(for: "Lab 3.PDF", id: id) == "6F9619FF-8B86-D011-B42D-00C04FC964FF.pdf")
    #expect(CourseLink.storedName(for: "notes", id: id) == "6F9619FF-8B86-D011-B42D-00C04FC964FF")
}

@Test func theLinksStayInTheBackup() throws {
    var data = AppData()
    data.links = [CourseLink(course: "Automatizim", title: "Moodle", url: "https://moodle.upt.al")]
    #expect(try AppData.restore(data.backup()).links == data.links)
}
