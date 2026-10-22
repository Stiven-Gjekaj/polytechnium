import Foundation

/// All data of the app, in one file that the app and the widgets share.
public struct AppData: Codable, Hashable, Sendable {
    /// The form of the file. A newer form that an older app cannot read raises it.
    ///
    /// Form 2 adds the attendance, the quick links, and the study plan.
    public static let currentVersion = 2

    public var version = AppData.currentVersion
    public var timetable: Timetable?
    public var week: Week?
    public var courses: [CourseGrade] = []
    /// The scale of the grades. Nil is the standard scale.
    public var scale: GradeScale?
    public var exams: [Exam] = []
    public var deadlines: [Deadline] = []
    public var attendance: [AttendanceMark] = []
    public var links: [CourseLink] = []
    public var studyDone: [StudyDone] = []
    /// The most hours of revision on one day. Nil is the default.
    public var studyHoursPerDay: Double?
    /// The days of revision before an exam. Nil is the default.
    public var studyDays: Int?
    /// The part of the classes that the student must be at, in percent, for each course.
    public var requiredAttendance: [String: Double] = [:]
    /// The weeks of classes in the semester. Nil is 15.
    public var semesterWeeks: Int?

    public init(timetable: Timetable? = nil, week: Week? = nil, courses: [CourseGrade] = []) {
        self.timetable = timetable
        self.week = week
        self.courses = courses
    }

    public var gradeScale: GradeScale { scale ?? .standard }

    /// The weeks of classes in the semester.
    public var weeks: Int { semesterWeeks ?? 15 }

    /// The study plan of the exams from the day of `now`.
    public func studyPlan(at now: Date) -> StudyPlan {
        StudyPlan(
            exams: exams, done: studyDone, now: now,
            perDay: studyHoursPerDay ?? StudyPlan.defaultHoursPerDay, days: studyDays ?? StudyPlan.defaultDays
        )
    }

    /// The classes of a day that are over and have no mark of attendance yet.
    public func unmarked(on now: Date, calendar: Calendar = Week.calendar) -> [Occurrence] {
        guard let timetable else { return [] }
        return weekOrDefault(at: now).ended(in: timetable, on: now, calendar: calendar).filter { occurrence in
            !attendance.contains {
                $0.course == occurrence.session.course && $0.kind == occurrence.session.kind
                    && calendar.isDate($0.date, inSameDayAs: occurrence.start)
            }
        }
    }

    /// The attendance of one course.
    public func attendanceSummary(for course: String) -> AttendanceSummary {
        AttendanceSummary(
            course: course, marks: attendance, timetable: timetable, weeks: weeks,
            required: requiredAttendance[course] ?? AttendanceSummary.defaultRequired
        )
    }

    /// The week of the data, or a week that is odd from the Monday of `date`.
    public func weekOrDefault(at date: Date) -> Week {
        week ?? Week(oddMonday: Week.monday(of: date))
    }

    enum CodingKeys: String, CodingKey {
        case version, timetable, week, courses, scale, exams, deadlines, attendance, requiredAttendance, semesterWeeks, links, studyDone, studyHoursPerDay, studyDays
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // The data of an older form reads into this form, and saves in it.
        version = AppData.currentVersion
        timetable = try container.decodeIfPresent(Timetable.self, forKey: .timetable)
        week = try container.decodeIfPresent(Week.self, forKey: .week)
        courses = try container.decodeIfPresent([CourseGrade].self, forKey: .courses) ?? []
        scale = try container.decodeIfPresent(GradeScale.self, forKey: .scale)
        exams = try container.decodeIfPresent([Exam].self, forKey: .exams) ?? []
        deadlines = try container.decodeIfPresent([Deadline].self, forKey: .deadlines) ?? []
        attendance = try container.decodeIfPresent([AttendanceMark].self, forKey: .attendance) ?? []
        requiredAttendance = try container.decodeIfPresent([String: Double].self, forKey: .requiredAttendance) ?? [:]
        semesterWeeks = try container.decodeIfPresent(Int.self, forKey: .semesterWeeks)
        links = try container.decodeIfPresent([CourseLink].self, forKey: .links) ?? []
        studyDone = try container.decodeIfPresent([StudyDone].self, forKey: .studyDone) ?? []
        studyHoursPerDay = try container.decodeIfPresent(Double.self, forKey: .studyHoursPerDay)
        studyDays = try container.decodeIfPresent(Int.self, forKey: .studyDays)
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
