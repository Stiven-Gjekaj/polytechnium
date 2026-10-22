import PolyCore
import SwiftUI
import UIKit

/// The credits, the parts, and the points of one course, with the what-if mode.
struct CourseGradeEditor: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var course: CourseGrade
    @State private var target = 8
    @State private var confirmDelete = false
    private let isNew: Bool

    init(course: CourseGrade) {
        _course = State(initialValue: course)
        isNew = course.name.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(tr("Course")) {
                    TextField(tr("Name"), text: $course.name)
                    LabeledContent(tr("Credits")) {
                        TextField(tr("Credits"), value: $course.credits, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                Section {
                    ForEach($course.components) { $part in
                        PartRow(part: $part)
                    }
                    .onDelete { course.components.remove(atOffsets: $0) }
                    Button(tr("Add a part"), systemImage: "plus") {
                        course.components.append(GradeComponent(name: tr("Labs"), weight: 0))
                    }
                } header: {
                    Text(tr("Parts of the grade"))
                } footer: {
                    Text(weightNote)
                }
                Section {
                    Picker(tr("Grade"), selection: $course.finalGrade) {
                        Text(tr("From the points")).tag(Int?.none)
                        ForEach(4...10, id: \.self) { Text(String($0)).tag(Int?.some($0)) }
                    }
                } header: {
                    Text(tr("Grade of the faculty"))
                } footer: {
                    Text(tr("Choose the grade when the faculty gives it. It takes the place of the grade from the points."))
                }
                Section {
                    Picker(tr("Grade that I want"), selection: $target) {
                        ForEach(5...10, id: \.self) { Text(String($0)).tag($0) }
                    }
                    Text(whatIf)
                        .font(Karla.font(16, .semibold))
                } header: {
                    Text(tr("What if"))
                } footer: {
                    Text(tr("Leave the points of a part empty while it is not done. The app finds the points that these parts need."))
                }
                if !isNew {
                    Section {
                        Button(tr("Delete the course"), role: .destructive) { confirmDelete = true }
                            .foregroundStyle(Palette.danger)
                    }
                }
            }
            .polyForm()
            .polyScreen()
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isNew ? tr("Add a course") : course.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(tr("Cancel")) { dismiss() }
                }
                // The number pad has no key that closes it. A number goes into
                // the course when the field loses the focus.
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(tr("Done")) { Self.endTyping() }
                        .font(Karla.font(16, .bold))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(tr("Save")) {
                        Self.endTyping()
                        course.name = course.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        app.save(course)
                        dismiss()
                    }
                    .font(Karla.font(16, .bold))
                    .disabled(course.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .confirmationDialog(tr("Delete this course?"), isPresented: $confirmDelete, titleVisibility: .visible) {
                Button(tr("Delete"), role: .destructive) {
                    app.delete(course)
                    dismiss()
                }
            }
        }
    }

    /// Closes the keyboard, so that the field gives its number to the course.
    static func endTyping() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private var weightNote: String {
        let total = course.totalWeight
        if abs(total - 100) < 0.01 { return tr("The weights give 100%.") }
        return tr("The weights give %@%%, not 100%%. The app counts each part in its share.", GradesScreen.number(total))
    }

    /// The answer of the what-if mode, such as "You need 58 points on Final exam."
    private var whatIf: String {
        let open = course.components.filter { $0.score == nil }.map(\.name)
        switch course.needed(for: target, on: app.data.gradeScale) {
        case .secured:
            return tr("Your points give a %d already.", target)
        case let .needs(average):
            let points = GradesScreen.number(average)
            return open.count == 1
                ? tr("You need %@ points on %@.", points, open[0])
                : tr("You need %@ points on average on %@.", points, ListFormatter.localizedString(byJoining: open))
        case let .impossible(best):
            return best.map { tr("A %d is not possible. The best grade that is possible is %d.", target, $0) }
                ?? tr("A %d is not possible.", target)
        case .noParts:
            return tr("Add the parts of the grade first.")
        }
    }
}

/// One part of the grade: the name, the weight, and the points.
private struct PartRow: View {
    @Binding var part: GradeComponent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(tr("Part"), text: $part.name)
                .font(Karla.font(16, .semibold))
            HStack(spacing: 12) {
                LabeledContent(tr("Weight %")) {
                    TextField("0", value: $part.weight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 56)
                }
                Divider()
                LabeledContent(tr("Points")) {
                    TextField(tr("Not done"), value: $part.score, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }
            .font(Karla.font(14))
            .foregroundStyle(Palette.textSecondary)
        }
        .padding(.vertical, 4)
    }
}
