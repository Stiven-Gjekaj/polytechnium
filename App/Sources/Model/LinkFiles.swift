import Foundation
import PolyCore

/// The folder of the files of the quick links, next to the data file.
enum LinkFiles {
    static var folder: URL {
        AppGroup.store.url.deletingLastPathComponent().appendingPathComponent("Files", isDirectory: true)
    }

    static func url(of link: CourseLink) -> URL? {
        link.fileName.map { folder.appendingPathComponent($0) }
    }

    /// Copies a file that the user chose into the folder, and gives the name of the copy.
    static func copy(_ source: URL, id: UUID) throws -> String {
        let access = source.startAccessingSecurityScopedResource()
        defer { if access { source.stopAccessingSecurityScopedResource() } }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let name = CourseLink.storedName(for: source.lastPathComponent, id: id)
        try FileManager.default.copyItem(at: source, to: folder.appendingPathComponent(name))
        return name
    }

    static func remove(_ link: CourseLink) {
        if let url = url(of: link) { try? FileManager.default.removeItem(at: url) }
    }
}
