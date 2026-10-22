import PolyCore
import SwiftUI

/// Adds an exam or changes one.
struct ExamEditor: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var exam: Exam
    @State private var confirmDelete = false
    private let isNew: Bool

    init(exam: Exam) {
        _exam = State(initialValue: exam)
        isNew = exam.course.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(tr("Exam")) {
                    TextField(tr("Course"), text: $exam.course)
                    if !app.courseNames.isEmpty {
                        Picker(tr("Course of the timetable"), selection: $exam.course) {
                            if !app.courseNames.contains(exam.course) { Text(exam.course.isEmpty ? "-" : exam.course).tag(exam.course) }
                            ForEach(app.courseNames, id: \.self) { Text($0).tag($0) }
                        }
                    }
                    DatePicker(tr("Date"), selection: $exam.date)
                    TextField(tr("Room"), text: $exam.room)
                    TextField(tr("Note"), text: $exam.note, axis: .vertical)
                }
                Section {
                    Toggle(tr("Reminders"), isOn: $exam.remind)
                        .tint(Palette.textSecondary)
                } footer: {
                    Text(tr("At 18:00 one week, three days, and one day before the exam."))
                }
                if !isNew {
                    Section {
                        Button(tr("Delete the exam"), role: .destructive) { confirmDelete = true }
                            .foregroundStyle(Palette.danger)
                    }
                }
            }
            .polyForm()
            .polyScreen()
            .environment(\.locale, L10n.locale)
            .navigationTitle(isNew ? tr("Add an exam") : exam.course)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(tr("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(tr("Save")) {
                        exam.course = exam.course.trimmingCharacters(in: .whitespacesAndNewlines)
                        app.save(exam)
                        dismiss()
                    }
                    .font(Karla.font(16, .bold))
                    .disabled(exam.course.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .confirmationDialog(tr("Delete this exam?"), isPresented: $confirmDelete, titleVisibility: .visible) {
                Button(tr("Delete"), role: .destructive) {
                    app.delete(exam)
                    dismiss()
                }
            }
        }
    }
}
