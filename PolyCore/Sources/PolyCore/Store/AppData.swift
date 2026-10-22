import Foundation

/// All data of the app, in one file that the app and the widgets share.
public struct AppData: Codable, Hashable, Sendable {
    /// The form of the file. A newer form that an older app cannot read raises it.
    public static let currentVersion = 1

    public var version = AppData.currentVersion
    public var timetable: Timetable?
    public var week: Week?
    public var courses: [CourseGrade] = []
    /// The scale of the grades. Nil is the standard scale.
    public var scale: GradeScale?

    public init(timetable: Timetable? = nil, week: Week? = nil, courses: [CourseGrade] = []) {
        self.timetable = timetable
        self.week = week
        self.courses = courses
    }

    public var gradeScale: GradeScale { scale ?? .standard }

    /// The week of the data, or a week that is odd from the Monday of `date`.
    public func weekOrDefault(at date: Date) -> Week {
        week ?? Week(oddMonday: Week.monday(of: date))
    }

    enum CodingKeys: String, CodingKey {
        case version, timetable, week, courses, scale
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        timetable = try container.decodeIfPresent(Timetable.self, forKey: .timetable)
        week = try container.decodeIfPresent(Week.self, forKey: .week)
        courses = try container.decodeIfPresent([CourseGrade].self, forKey: .courses) ?? []
        scale = try container.decodeIfPresent(GradeScale.self, forKey: .scale)
    }
}

/// Reads and writes the data file.
public struct DataStore: Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    /// The store in the shared folder of an app group, or in the documents of the
    /// app when the group is not available.
    public static func shared(group: String) -> DataStore {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        guard let folder = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else {
            return DataStore(url: documents)
        }
        let store = DataStore(url: folder.appendingPathComponent(fileName))
        store.moveIn(from: documents)
        return store
    }

    static let fileName = "polytechnium.json"

    /// Moves a data file from an older place, when this store has no file yet.
    /// An install with no app group keeps the file in the documents of the app.
    public func moveIn(from old: URL) {
        let files = FileManager.default
        guard !files.fileExists(atPath: url.path), files.fileExists(atPath: old.path) else { return }
        try? files.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? files.moveItem(at: old, to: url)
    }

    /// The data on the disk. A missing file gives empty data.
    public func load() throws -> AppData {
        guard FileManager.default.fileExists(atPath: url.path) else { return AppData() }
        let data = try Data(contentsOf: url)
        return try Self.decoder.decode(AppData.self, from: data)
    }

    /// Writes the data in one step, so that a widget never reads half a file.
    public func save(_ data: AppData) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Self.encoder.encode(data).write(to: url, options: .atomic)
    }

    public static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    public static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
