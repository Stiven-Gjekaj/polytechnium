import PolyCore
import SwiftUI

/// The language, the weeks, the timetable, and the facts about the app.
struct SettingsScreen: View {
    @Environment(AppModel.self) private var app
    @State private var confirmClear = false
    @State private var showFontLicense = false

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
                } header: {
                    Text(tr("Weeks"))
                } footer: {
                    Text(tr("The timetable writes tek for the odd weeks and cift for the even weeks. Choose the kind of this week, and the app counts the next weeks."))
                }
                Section(tr("Timetable")) {
                    if let group = app.timetable?.group, !group.isEmpty {
                        LabeledContent(tr("Group"), value: group)
                    }
                    if app.timetable != nil {
                        Button(tr("Delete the timetable"), role: .destructive) { confirmClear = true }
                            .foregroundStyle(Palette.danger)
                    }
                }
                Section {
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
                    Text(tr("Polytechnium is for the students of the Polytechnic University of Tirana. It is not an app of the university. Your data stays on this device."))
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
