import PolyCore
import SwiftUI

/// Adds a deadline or changes one.
struct DeadlineEditor: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var deadline: Deadline
    @State private var confirmDelete = false
    private let isNew: Bool

    init(deadline: Deadline) {
        _deadline = State(initialValue: deadline)
        isNew = deadline.title.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(tr("Deadline")) {
                    TextField(tr("Title, such as Lab report 3"), text: $deadline.title)
                    Picker(tr("Kind"), selection: $deadline.kind) {
                        ForEach(Deadline.Kind.allCases, id: \.self) { Text($0.name).tag($0) }
                    }
                    TextField(tr("Course"), text: $deadline.course)
                    if !app.courseNames.isEmpty {
                        Picker(tr("Course of the timetable"), selection: $deadline.course) {
                            if !app.courseNames.contains(deadline.course) {
                                Text(deadline.course.isEmpty ? "-" : deadline.course).tag(deadline.course)
                            }
                            ForEach(app.courseNames, id: \.self) { Text($0).tag($0) }
                        }
                    }
                    DatePicker(tr("Due"), selection: $deadline.due)
                    Toggle(tr("Handed in"), isOn: $deadline.done)
                        .tint(Palette.textSecondary)
                }
                Section {
                    Toggle(tr("Reminders"), isOn: $deadline.remind)
                        .tint(Palette.textSecondary)
                } footer: {
                    Text(tr("One day and two hours before the deadline."))
                }
                if !isNew {
                    Section {
                        Button(tr("Delete the deadline"), role: .destructive) { confirmDelete = true }
                            .foregroundStyle(Palette.danger)
                    }
                }
            }
            .polyForm()
            .polyScreen()
            .environment(\.locale, L10n.locale)
            .navigationTitle(isNew ? tr("Add a deadline") : deadline.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(tr("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(tr("Save")) {
                        deadline.title = deadline.title.trimmingCharacters(in: .whitespacesAndNewlines)
                        app.save(deadline)
                        dismiss()
                    }
                    .font(Karla.font(16, .bold))
                    .disabled(deadline.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .confirmationDialog(tr("Delete this deadline?"), isPresented: $confirmDelete, titleVisibility: .visible) {
                Button(tr("Delete"), role: .destructive) {
                    app.delete(deadline)
                    dismiss()
                }
            }
        }
    }
}
