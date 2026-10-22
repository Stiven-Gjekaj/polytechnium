import PolyCore
import QuickLook
import SwiftUI

/// The page of one course: its quick links and its attendance.
struct CourseScreen: View {
    @Environment(AppModel.self) private var app
    let course: String
    @State private var date = Date.now
    @State private var kind: SessionKind = .seminar
    @State private var addingLink = false
    @State private var addingFile = false
    @State private var preview: URL?
    @Environment(\.openURL) private var openURL

    var body: some View {
        let summary = app.data.attendanceSummary(for: course)
        Form {
            links
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(summary.rate.map { $0.formatted(.percent.precision(.fractionLength(0)).locale(L10n.locale)) } ?? "-")
                        .font(Karla.font(40, .bold, relativeTo: .largeTitle))
                    Text(AttendanceText.line(summary))
                        .foregroundStyle(Palette.textSecondary)
                    Text(AttendanceText.canMiss(summary))
                        .font(Karla.font(15, .semibold))
                        .foregroundStyle(summary.canMiss < 0 ? Palette.danger : Palette.textPrimary)
                }
                .padding(.vertical, 6)
                Stepper(value: Binding(get: { summary.required }, set: { app.setRequired($0, for: course) }), in: 0...100, step: 5) {
                    LabeledContent(tr("Required"), value: summary.required.formatted(.number) + "%")
                }
            } header: {
                Text(tr("Attendance"))
            } footer: {
                Text(tr("The app counts %d classes of this course in %d weeks, from the timetable.", summary.planned, app.data.weeks))
            }
            Section(tr("Mark a class")) {
                DatePicker(tr("Date"), selection: $date)
                Picker(tr("Kind"), selection: $kind) {
                    ForEach(SessionKind.allCases, id: \.self) { Text($0.name).tag($0) }
                }
                HStack {
                    Button(tr("I was there")) { app.mark(course, kind: kind, on: date, present: true) }
                        .buttonStyle(.polyPrimary)
                    Button(tr("I missed it")) { app.mark(course, kind: kind, on: date, present: false) }
                        .buttonStyle(.polySecondary)
                }
                .frame(maxWidth: .infinity)
            }
            let marks = app.data.attendance.filter { $0.course == course }.sorted { $0.date > $1.date }
            if !marks.isEmpty {
                Section(tr("Marks")) {
                    ForEach(marks) { mark in
                        HStack {
                            Image(systemName: mark.present ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundStyle(mark.present ? Palette.accent : Palette.danger)
                                .accessibilityLabel(mark.present ? tr("Was there") : tr("Missed"))
                            Text(mark.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(L10n.locale)))
                            Spacer()
                            Text(mark.kind.name)
                                .foregroundStyle(Palette.textSecondary)
                        }
                    }
                    .onDelete { offsets in offsets.map { marks[$0] }.forEach(app.delete) }
                }
            }
        }
        .polyForm()
        .polyScreen()
        .environment(\.locale, L10n.locale)
        .navigationTitle(course)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { kind = Self.likelyKind(of: course, in: app.timetable) }
        .sheet(isPresented: $addingLink) { LinkEditor(course: course) }
        .fileImporter(isPresented: $addingFile, allowedContentTypes: [.item]) { result in
            if case let .success(url) = result { app.addFile(url, to: course) }
        }
        .quickLookPreview($preview)
    }

    /// The quick links of the course, with the buttons that add one.
    private var links: some View {
        let own = app.data.links.filter { $0.course == course }
        return Section {
            ForEach(own) { link in
                Button { open(link) } label: {
                    Label(link.title, systemImage: link.isFile ? "doc.text" : "globe")
                        .foregroundStyle(Palette.textPrimary)
                }
            }
            .onDelete { offsets in offsets.map { own[$0] }.forEach(app.delete) }
            Button(tr("Add a web link"), systemImage: "link") { addingLink = true }
            Button(tr("Add a file"), systemImage: "doc.badge.plus") { addingFile = true }
        } header: {
            Text(tr("Quick links"))
        } footer: {
            Text(tr("Notes, PDFs, and lab sheets. A file stays on this device and is not in the backup."))
        }
    }

    private func open(_ link: CourseLink) {
        if let file = LinkFiles.url(of: link) {
            preview = file
        } else if let address = link.url, let url = URL(string: address) {
            openURL(url)
        }
    }

    /// The kind of the most classes of the course, such as a seminar.
    static func likelyKind(of course: String, in timetable: Timetable?) -> SessionKind {
        let kinds = (timetable?.sessions ?? []).filter { $0.course == course }.map(\.kind)
        return Dictionary(kinds.map { ($0, 1) }, uniquingKeysWith: +).max { $0.value < $1.value }?.key ?? .seminar
    }
}

/// Adds a quick link to a web page.
private struct LinkEditor: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    let course: String
    @State private var title = ""
    @State private var address = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField(tr("Title, such as Moodle"), text: $title)
                TextField(tr("Address"), text: $address)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .polyForm()
            .polyScreen()
            .navigationTitle(tr("Add a web link"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(tr("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(tr("Save")) {
                        guard let url = CourseLink.webAddress(address) else { return }
                        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        app.addLink(name.isEmpty ? (url.host ?? url.absoluteString) : name, url: url, to: course)
                        dismiss()
                    }
                    .font(Karla.font(16, .bold))
                    .disabled(CourseLink.webAddress(address) == nil)
                }
            }
        }
    }
}
