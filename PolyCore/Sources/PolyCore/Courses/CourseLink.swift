import Foundation

/// A quick link of a course: a web page, or a file that the app keeps, such as
/// the notes, a PDF, or a lab sheet.
public struct CourseLink: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var course: String
    public var title: String
    /// The address of a web page. Nil for a file.
    public var url: String?
    /// The name of the file in the folder of the files of the app. Nil for a web page.
    public var fileName: String?

    public init(id: UUID = UUID(), course: String, title: String, url: String? = nil, fileName: String? = nil) {
        self.id = id
        self.course = course
        self.title = title
        self.url = url
        self.fileName = fileName
    }

    public var isFile: Bool { fileName != nil }

    /// The address of a web page that the user writes, with "https://" when it
    /// has no scheme. Nil for a text that is not an address.
    public static func webAddress(_ text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains(" ") else { return nil }
        let full = trimmed.contains("://") ? trimmed : "https://" + trimmed
        guard let url = URL(string: full), let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme), let host = url.host, host.contains(".")
        else { return nil }
        return url
    }

    /// A name for a copy of a file, with the extension of the file, so that two
    /// files with the same name do not replace each other.
    public static func storedName(for original: String, id: UUID) -> String {
        let ext = (original as NSString).pathExtension
        return ext.isEmpty ? id.uuidString : "\(id.uuidString).\(ext.lowercased())"
    }
}
