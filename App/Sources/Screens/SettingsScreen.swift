import PolyCore
import SwiftUI
import UniformTypeIdentifiers

/// The language, the weeks, the timetable, and the facts about the app.
struct SettingsScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var importing = false
    @State private var confirmClear = false
    @State private var showFontLicense = false
    @State private var newer: String?
    @State private var exporting: BackupFile?
    @State private var restoring = false
    @State private var pending: AppData?
    @State private var backupFault: String?

    var body: some View {
        @Bindable var app = app
        NavigationStack {
            Form {
                Section(tr("Language")) {
                    Picker(tr("Language"), selection: $app.language) {
                        ForEach(AppLanguage.allCases) { Text($0.name).tag($0) }
                    }
                }
                Section {
                    Picker(tr("This week"), selection: Binding(
                        get: { app.week.parity(of: .now) },
                        set: { app.setThisWeek($0) }
                    )) {
                        Text(WeekParity.odd.weekName).tag(WeekParity.odd)
                        Text(WeekParity.even.weekName).tag(WeekParity.even)
                    }
                    Stepper(value: Binding(get: { app.data.weeks }, set: { weeks in app.update { $0.semesterWeeks = weeks } }), in: 1...30) {
                        LabeledContent(tr("Weeks of classes"), value: String(app.data.weeks))
                    }
                } header: {
                    Text(tr("Weeks"))
                } footer: {
                    Text(tr("The timetable writes tek for the odd weeks and cift for the even weeks. Choose the kind of this week, and the app counts the next weeks."))
                }
                Section(tr("Timetable")) {
                    if let group = app.timetable?.group, !group.isEmpty {
                        LabeledContent(tr("Group"), value: group)
                    }
                    Button(tr("Import a PDF")) { importing = true }
                    if app.timetable != nil {
                        Button(tr("Delete the timetable"), role: .destructive) { confirmClear = true }
                            .foregroundStyle(Palette.danger)
                    }
                }
                Section {
                    Button(tr("Save a backup")) {
                        if let data = try? app.data.backup() { exporting = BackupFile(data: data) }
                    }
                    Button(tr("Restore a backup")) { restoring = true }
                } header: {
                    Text(tr("Backup"))
                } footer: {
                    Text(tr("The backup is one file with your timetable, grades, exams, and deadlines. Keep it in Files or in iCloud Drive."))
                }
                Section {
                    if let newer {
                        Link(destination: URL(string: AppInfo.repository + "/releases/latest")!) {
                            Label(tr("Version %@ is available", newer), systemImage: "arrow.down.circle")
                        }
                        .font(Karla.font(16, .bold))
                    }
                    Link(destination: URL(string: AppInfo.kofi)!) {
                        Label(tr("Support the project on Ko-fi"), systemImage: "cup.and.saucer")
                    }
                    Link(destination: URL(string: AppInfo.repository)!) {
                        Label(tr("Source code on GitHub"), systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    LabeledContent(tr("Version"), value: AppInfo.version)
                } header: {
                    Text(tr("About"))
                } footer: {
                    Text(tr("Polytechnium is for the students of the Polytechnic University of Tirana. It is not an app of the university. Your data stays on this device. The app asks GitHub for the newest version."))
                }
                Section(tr("Licenses")) {
                    Text(tr("The code is under the MIT License. Karla, the font of the app, is under the SIL Open Font License, Version 1.1."))
                        .foregroundStyle(Palette.textSecondary)
                    Button(showFontLicense ? tr("Hide the font license") : tr("Show the font license")) {
                        showFontLicense.toggle()
                    }
                    if showFontLicense {
                        Text(Self.fontLicense)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Palette.textSecondary)
                            .textSelection(.enabled)
                    }
                }
            }
            .polyForm()
            .polyScreen()
            .navigationTitle(tr("Settings"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(tr("Done")) { dismiss() }
                        .font(Karla.font(16, .bold))
                }
            }
            .sheet(isPresented: $importing) { ImportScreen() }
            .task { newer = await UpdateCheck.newerVersion() }
            .fileExporter(
                isPresented: Binding(get: { exporting != nil }, set: { if !$0 { exporting = nil } }),
                document: exporting,
                contentType: .json,
                defaultFilename: "Polytechnium " + Date.now.formatted(.iso8601.year().month().day())
            ) { _ in exporting = nil }
            .fileImporter(isPresented: $restoring, allowedContentTypes: [.json]) { result in
                guard case let .success(url) = result else { return }
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                do {
                    pending = try AppData.restore(Data(contentsOf: url))
                } catch AppData.BackupFailure.tooNew {
                    backupFault = tr("A newer version of the app made this backup. Update the app first.")
                } catch {
                    backupFault = tr("This file is not a backup of Polytechnium.")
                }
            }
            .confirmationDialog(
                tr("Restore the backup?"),
                isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } }),
                titleVisibility: .visible
            ) {
                Button(tr("Restore"), role: .destructive) {
                    if let pending { app.restore(pending) }
                    pending = nil
                }
            } message: {
                Text(tr("The data of the backup takes the place of all data in the app."))
            }
            .alert(tr("Fault"), isPresented: Binding(get: { backupFault != nil }, set: { if !$0 { backupFault = nil } })) {
                Button(tr("OK")) { backupFault = nil }
            } message: {
                Text(backupFault ?? "")
            }
            .confirmationDialog(tr("Delete the timetable?"), isPresented: $confirmClear, titleVisibility: .visible) {
                Button(tr("Delete"), role: .destructive) { app.update { $0.timetable = nil } }
            }
        }
    }

    /// The text of the SIL Open Font License, from the file next to the font.
    static var fontLicense: String {
        guard let url = Bundle.main.url(forResource: "Karla-OFL", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else { return "SIL Open Font License, Version 1.1: https://openfontlicense.org" }
        return text
    }
}
