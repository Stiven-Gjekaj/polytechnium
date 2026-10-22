import PolyCore
import SwiftUI
import UniformTypeIdentifiers

/// Reads a timetable PDF of the faculty, lets the user choose a group, and saves
/// the classes of that group.
struct ImportScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var picking = true
    @State private var reading = false
    @State private var grid: TimetableGrid?
    @State private var group: String?
    @State private var search = ""
    @State private var fault: String?
    @State private var confirmReplace = false

    var body: some View {
        NavigationStack {
            Group {
                if reading {
                    ProgressView(tr("Reading the timetable"))
                        .font(Karla.font(15))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let grid, let group {
                    preview(grid.timetable(for: group))
                } else if let grid {
                    groups(grid)
                } else {
                    EmptyMessage(text: fault ?? tr("Choose the timetable PDF of the faculty."), action: tr("Choose a PDF")) {
                        picking = true
                    }
                }
            }
            .polyScreen()
            .navigationTitle(group ?? tr("Import a timetable"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(tr("Cancel")) { dismiss() }
                }
                if group != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(tr("Groups")) { group = nil }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(tr("Save")) {
                            if app.timetable?.sessions.isEmpty == false { confirmReplace = true } else { save() }
                        }
                        .font(Karla.font(16, .bold))
                    }
                }
            }
            .fileImporter(isPresented: $picking, allowedContentTypes: [.pdf]) { result in
                switch result {
                case let .success(url): read(url)
                case let .failure(error): fault = error.localizedDescription
                }
            }
            .confirmationDialog(tr("Replace your timetable?"), isPresented: $confirmReplace, titleVisibility: .visible) {
                Button(tr("Replace"), role: .destructive, action: save)
            } message: {
                Text(tr("The classes of this group take the place of your classes, also of the classes that you changed."))
            }
        }
    }

    private func groups(_ grid: TimetableGrid) -> some View {
        let shown = grid.groups.filter { search.isEmpty || $0.localizedCaseInsensitiveContains(search) }
        return List(shown, id: \.self) { name in
            Button {
                group = name
            } label: {
                HStack {
                    Text(name)
                        .font(Karla.font(16, .semibold))
                    Spacer()
                    Text(tr("%d classes", grid.sessions[name]?.count ?? 0))
                        .font(Karla.font(14))
                        .foregroundStyle(Palette.textSecondary)
                }
            }
            .listRowBackground(Palette.surface)
        }
        .polyForm()
        .searchable(text: $search, prompt: tr("Find a group, such as II-A-ELN"))
    }

    private func preview(_ timetable: Timetable) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(tr("Look at the classes. You can change each class after you save."))
                    .font(Karla.font(14))
                    .foregroundStyle(Palette.textSecondary)
                ForEach(Array(Set(timetable.sessions.map(\.weekday))).sorted(), id: \.self) { day in
                    SectionTitle(text: Weekdays.name(day))
                        .padding(.top, 8)
                    ForEach(timetable.sessions.filter { $0.weekday == day }) { session in
                        ClassRow(session: session)
                    }
                }
            }
            .padding(gutter)
        }
    }

    private func read(_ url: URL) {
        reading = true
        fault = nil
        Task {
            let result = await Task.detached(priority: .userInitiated) { () -> Result<TimetableGrid, Error> in
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                return Result { try TimetablePDF.read(Data(contentsOf: url)) }
            }.value
            reading = false
            switch result {
            case let .success(read):
                grid = read
                group = Self.likelyGroup(in: read, previous: app.timetable?.group)
            case let .failure(error as TimetablePDF.Failure):
                fault = error == .notAPDF
                    ? tr("This file is not a PDF.")
                    : tr("This PDF has no timetable. The app reads the timetable of the faculty, with the hours in a column named ORA.")
            case let .failure(error):
                fault = error.localizedDescription
            }
        }
    }

    /// The group of the last import, when the new PDF has it.
    static func likelyGroup(in grid: TimetableGrid, previous: String?) -> String? {
        guard let previous, grid.groups.contains(previous) else { return nil }
        return previous
    }

    private func save() {
        guard let grid, let group else { return }
        app.replaceTimetable(with: grid.timetable(for: group))
        dismiss()
    }
}
