import Foundation
import Observation
import PolyCore
import WidgetKit

/// The data of the app, which each screen reads and changes.
@MainActor @Observable
final class AppModel {
    private(set) var data: AppData
    /// The fault of the last read or write of the data file, for the user.
    var fault: String?
    var language: AppLanguage {
        didSet {
            AppLanguage.chosen = language
            WidgetCenter.shared.reloadAllTimelines()
        }
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
        // A reminder in the past drops out, and the next ones come in.
        Notifications.reschedule(data)
    }

    var timetable: Timetable? { data.timetable }

    /// The week of the data. With no week, the current week is odd.
    var week: Week { data.weekOrDefault(at: .now) }

    /// Changes the data and writes it to the disk.
    func update(_ change: (inout AppData) -> Void) {
        change(&data)
        do {
            try store.save(data)
            WidgetCenter.shared.reloadAllTimelines()
            Notifications.reschedule(data)
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

    /// Adds a course of the grades, or changes the course with the same identifier.
    func save(_ course: CourseGrade) {
        update { data in
            if let index = data.courses.firstIndex(where: { $0.id == course.id }) {
                data.courses[index] = course
            } else {
                data.courses.append(course)
            }
        }
    }

    func delete(_ course: CourseGrade) {
        update { $0.courses.removeAll { $0.id == course.id } }
    }

    /// The courses of the timetable that are not in the grades yet.
    var coursesToAdd: [String] {
        let known = Set(data.courses.map { $0.name.lowercased() })
        return (timetable?.courses ?? []).filter { !known.contains($0.lowercased()) }
    }

    /// Adds each course of the timetable to the grades, with a midterm and a final.
    func addTimetableCourses() {
        let names = coursesToAdd
        update { data in
            data.courses += names.map { name in
                CourseGrade(name: name, credits: 0, components: [
                    GradeComponent(name: tr("Midterm"), weight: 40),
                    GradeComponent(name: tr("Final exam"), weight: 60),
                ])
            }
        }
    }

    /// Adds an exam, or changes the exam with the same identifier.
    func save(_ exam: Exam) {
        update { data in
            if let index = data.exams.firstIndex(where: { $0.id == exam.id }) {
                data.exams[index] = exam
            } else {
                data.exams.append(exam)
            }
            data.exams.sort { $0.date < $1.date }
        }
        if exam.remind {
            // A reminder that the app asks for before the permission does not show.
            Task {
                await Notifications.requestPermission()
                Notifications.reschedule(data)
            }
        }
    }

    func delete(_ exam: Exam) {
        update { $0.exams.removeAll { $0.id == exam.id } }
    }

    /// Adds a deadline, or changes the deadline with the same identifier.
    func save(_ deadline: Deadline) {
        update { data in
            if let index = data.deadlines.firstIndex(where: { $0.id == deadline.id }) {
                data.deadlines[index] = deadline
            } else {
                data.deadlines.append(deadline)
            }
            data.deadlines.sort { $0.due < $1.due }
        }
        if deadline.remind && !deadline.done {
            Task {
                await Notifications.requestPermission()
                Notifications.reschedule(data)
            }
        }
    }

    func delete(_ deadline: Deadline) {
        update { $0.deadlines.removeAll { $0.id == deadline.id } }
    }

    /// The names of the courses of the timetable and of the grades, for a choice.
    var courseNames: [String] {
        var names = timetable?.courses ?? []
        for course in data.courses.map(\.name) where !names.contains(where: { Timetable.isSameCourse($0, course) }) {
            names.append(course)
        }
        return names.sorted()
    }

    /// Marks one class of a course as attended or missed.
    func mark(_ course: String, kind: SessionKind, on date: Date, present: Bool) {
        update { $0.attendance.append(AttendanceMark(course: course, date: date, kind: kind, present: present)) }
    }

    func delete(_ mark: AttendanceMark) {
        update { $0.attendance.removeAll { $0.id == mark.id } }
    }

    /// Sets the part of the classes of a course that the student must be at.
    func setRequired(_ percent: Double, for course: String) {
        update { $0.requiredAttendance[course] = percent }
    }

    /// Puts the data of a backup in the place of all data.
    func restore(_ backup: AppData) {
        update { $0 = backup }
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
