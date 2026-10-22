import Foundation
import Observation
import PolyCore

/// The data of the app, which each screen reads and changes.
@MainActor @Observable
final class AppModel {
    private(set) var data: AppData
    /// The fault of the last read or write of the data file, for the user.
    var fault: String?
    var language: AppLanguage {
        didSet { AppLanguage.chosen = language }
    }

    private let store: DataStore

    init(store: DataStore = AppGroup.store) {
        self.store = store
        language = AppLanguage.chosen
        do {
            data = try store.load()
        } catch {
            data = AppData()
            fault = tr("The data file cannot be read: %@", error.localizedDescription)
        }
    }

    var timetable: Timetable? { data.timetable }

    /// The week of the data. With no week, the current week is odd.
    var week: Week { data.weekOrDefault(at: .now) }

    /// Changes the data and writes it to the disk.
    func update(_ change: (inout AppData) -> Void) {
        change(&data)
        do {
            try store.save(data)
        } catch {
            fault = tr("The data file cannot be written: %@", error.localizedDescription)
        }
    }

    /// Puts the classes of a group in the place of the timetable.
    func replaceTimetable(with timetable: Timetable) {
        update { $0.timetable = timetable }
    }

    /// Adds a class, or changes the class with the same identifier.
    func save(_ session: ClassSession) {
        update { data in
            var timetable = data.timetable ?? Timetable(group: "", sessions: [])
            var sessions = timetable.sessions.filter { $0.id != session.id }
            sessions.append(session)
            timetable = Timetable(group: timetable.group, sessions: sessions)
            data.timetable = timetable
        }
    }

    func delete(_ session: ClassSession) {
        update { data in
            guard let timetable = data.timetable else { return }
            data.timetable = Timetable(group: timetable.group, sessions: timetable.sessions.filter { $0.id != session.id })
        }
    }

    /// Makes the week of today odd or even.
    func setThisWeek(_ parity: WeekParity) {
        update { $0.week = Week.with(parity, at: .now) }
    }
}

enum AppInfo {
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    static let repository = "https://github.com/Stiven-Gjekaj/polytechnium"
    static let kofi = "https://ko-fi.com/stivengjekaj"
}
