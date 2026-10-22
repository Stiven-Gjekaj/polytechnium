import PolyCore
import SwiftUI

/// Adds a class or changes one: the course, the kind, the day, the hours, the
/// room, the lecturer, and the weeks.
struct ClassEditor: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var session: ClassSession
    @State private var confirmDelete = false
    private let isNew: Bool

    init(session: ClassSession) {
        _session = State(initialValue: session)
        isNew = session.course.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(tr("Class")) {
                    TextField(tr("Course"), text: $session.course)
                    Picker(tr("Kind"), selection: $session.kind) {
                        ForEach(SessionKind.allCases, id: \.self) { Text($0.name).tag($0) }
                    }
                }
                Section(tr("Time")) {
                    Picker(tr("Day"), selection: $session.weekday) {
                        ForEach(1...7, id: \.self) { Text(Weekdays.name($0)).tag($0) }
                    }
                    DatePicker(tr("Start"), selection: time(\.start), displayedComponents: .hourAndMinute)
                    DatePicker(tr("End"), selection: time(\.end), displayedComponents: .hourAndMinute)
                    Picker(tr("Weeks"), selection: $session.parity) {
                        ForEach(WeekParity.allCases, id: \.self) { Text($0.name).tag($0) }
                    }
                }
                Section(tr("Place")) {
                    TextField(tr("Room"), text: $session.room)
                    TextField(tr("Lecturer"), text: $session.lecturer)
                }
                if !isNew {
                    Section {
                        Button(tr("Delete the class"), role: .destructive) { confirmDelete = true }
                            .foregroundStyle(Palette.danger)
                    }
                }
            }
            .polyForm()
            .polyScreen()
            .environment(\.locale, Locale(identifier: "en_GB"))
            .navigationTitle(isNew ? tr("Add a class") : tr("Change the class"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(tr("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(tr("Save")) {
                        session.course = session.course.trimmingCharacters(in: .whitespacesAndNewlines)
                        app.save(session)
                        dismiss()
                    }
                    .font(Karla.font(16, .bold))
                    .disabled(!isValid)
                }
            }
            .confirmationDialog(tr("Delete this class?"), isPresented: $confirmDelete, titleVisibility: .visible) {
                Button(tr("Delete"), role: .destructive) {
                    app.delete(session)
                    dismiss()
                }
            }
        }
    }

    private var isValid: Bool {
        !session.course.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && session.end > session.start
    }

    /// The minutes of a class as a date of today, for the time picker.
    private func time(_ path: WritableKeyPath<ClassSession, Int>) -> Binding<Date> {
        let calendar = Week.calendar
        let midnight = calendar.startOfDay(for: .now)
        return Binding(
            get: { calendar.date(byAdding: .minute, value: session[keyPath: path], to: midnight) ?? midnight },
            set: { date in
                let parts = calendar.dateComponents([.hour, .minute], from: date)
                session[keyPath: path] = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
            }
        )
    }
}
