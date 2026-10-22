import PolyCore
import SwiftUI

/// The classes of each day of the week, with the import and the editor.
struct TimetableScreen: View {
    @Environment(AppModel.self) private var app
    @State private var weekday = min(Week.weekday(of: .now), 5)
    @State private var importing = false
    @State private var editing: ClassSession?

    var body: some View {
        NavigationStack {
            Group {
                if let timetable = app.timetable, !timetable.sessions.isEmpty {
                    content(timetable)
                } else {
                    EmptyMessage(
                        text: tr("Import the timetable PDF of the faculty, or add your classes one by one."),
                        action: tr("Import a PDF")
                    ) { importing = true }
                }
            }
            .polyScreen()
            .navigationTitle(tr("Timetable"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink { CoursesScreen() } label: {
                        Image(systemName: "books.vertical")
                            .accessibilityLabel(tr("Courses"))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(tr("Add a class"), systemImage: "plus") { editing = newSession() }
                        Button(tr("Import a PDF"), systemImage: "doc") { importing = true }
                    } label: {
                        Image(systemName: "plus")
                            .accessibilityLabel(tr("Add"))
                    }
                }
            }
            .sheet(isPresented: $importing) { ImportScreen() }
            .sheet(item: $editing) { session in ClassEditor(session: session) }
        }
    }

    private func content(_ timetable: Timetable) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(timetable.group.isEmpty ? tr("My classes") : timetable.group)
                        .font(Karla.font(15, .semibold))
                        .foregroundStyle(Palette.textSecondary)
                    Spacer()
                    Chip(text: tr("This week: %@", app.week.parity(of: .now).weekName.lowercased()))
                }
                dayPicker(timetable)
                let classes = timetable.sessions.filter { $0.weekday == weekday }
                if classes.isEmpty {
                    Text(tr("No classes on this day."))
                        .font(Karla.font(15))
                        .foregroundStyle(Palette.textSecondary)
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                }
                ForEach(classes) { session in
                    Button { editing = session } label: {
                        ClassRow(session: session, thisWeek: thisWeek(session))
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(tr("Delete"), systemImage: "trash", role: .destructive) { app.delete(session) }
                    }
                }
            }
            .padding(gutter)
        }
    }

    /// The days from Monday to Friday, and Saturday and Sunday when they have classes.
    private func dayPicker(_ timetable: Timetable) -> some View {
        let last = max(5, timetable.sessions.map(\.weekday).max() ?? 5)
        return HStack(spacing: 6) {
            ForEach(1...last, id: \.self) { day in
                Button { weekday = day } label: {
                    Text(Weekdays.short(day))
                        .font(Karla.font(14, .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .foregroundStyle(day == weekday ? Palette.onAccent : Palette.textPrimary)
                        .background(day == weekday ? Palette.accent : Palette.surfaceHigh, in: RoundedRectangle(cornerRadius: corner))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Weekdays.name(day))
                .accessibilityAddTraits(day == weekday ? .isSelected : [])
            }
        }
    }

    /// A class of odd weeks is not on in an even week.
    private func thisWeek(_ session: ClassSession) -> Bool {
        session.parity == .every || session.parity == app.week.parity(of: .now)
    }

    private func newSession() -> ClassSession {
        ClassSession(course: "", kind: .lecture, weekday: weekday, start: 480, end: 540)
    }
}

/// One class in a list: the time, the course, the kind, the room, and the lecturer.
struct ClassRow: View {
    let session: ClassSession
    var thisWeek = true

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Clock.text(session.start))
                    .font(Karla.font(16, .bold))
                Text(Clock.text(session.end))
                    .font(Karla.font(13))
                    .foregroundStyle(Palette.textSecondary)
            }
            .frame(width: 52, alignment: .leading)
            VStack(alignment: .leading, spacing: 6) {
                Text(session.course)
                    .font(Karla.font(16, .bold))
                    .multilineTextAlignment(.leading)
                HStack(spacing: 6) {
                    Chip(text: session.kind.name, filled: session.kind == .lecture)
                    if session.parity != .every { Chip(text: session.parity.name) }
                }
                if !details.isEmpty {
                    Text(details)
                        .font(Karla.font(14, relativeTo: .subheadline))
                        .foregroundStyle(Palette.textSecondary)
                }
            }
            Spacer(minLength: 0)
        }
        .card()
        .opacity(thisWeek ? 1 : 0.45)
        .accessibilityElement(children: .combine)
        .accessibilityHint(thisWeek ? "" : tr("Not on this week"))
    }

    private var details: String {
        var parts: [String] = []
        if !session.room.isEmpty { parts.append(tr("Room %@", session.room)) }
        if !session.lecturer.isEmpty { parts.append(session.lecturer) }
        return parts.joined(separator: "  ·  ")
    }
}
