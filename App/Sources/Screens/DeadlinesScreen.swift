import PolyCore
import SwiftUI

/// The lab reports and the assignments, with the time that is left to each one.
struct DeadlinesScreen: View {
    @Environment(AppModel.self) private var app
    @State private var editing: Deadline?

    var body: some View {
        NavigationStack {
            TimelineView(.everyMinute) { context in
                if app.data.deadlines.isEmpty {
                    EmptyMessage(
                        text: tr("Add your lab reports and assignments. The app reminds you one day and two hours before each one."),
                        action: tr("Add a deadline")
                    ) { editing = newDeadline() }
                } else {
                    content(now: context.date)
                }
            }
            .polyScreen()
            .navigationTitle(tr("Deadlines"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { editing = newDeadline() } label: {
                        Image(systemName: "plus")
                            .accessibilityLabel(tr("Add a deadline"))
                    }
                }
            }
            .sheet(item: $editing) { DeadlineEditor(deadline: $0) }
        }
    }

    private func content(now: Date) -> some View {
        let open = app.data.deadlines.filter { !$0.done }
        let done = app.data.deadlines.filter(\.done)
        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if open.isEmpty {
                    Text(tr("Nothing to hand in."))
                        .font(Karla.font(15))
                        .foregroundStyle(Palette.textSecondary)
                        .card()
                }
                ForEach(open) { row($0, now: now) }
                if !done.isEmpty {
                    SectionTitle(text: tr("Handed in"))
                        .padding(.top, 8)
                    ForEach(done.reversed()) { row($0, now: now).opacity(0.45) }
                }
            }
            .padding(gutter)
        }
    }

    private func row(_ deadline: Deadline, now: Date) -> some View {
        DeadlineRow(deadline: deadline, now: now, open: { editing = deadline }) {
            var changed = deadline
            changed.done.toggle()
            app.save(changed)
        }
        .contextMenu {
            Button(tr("Delete"), systemImage: "trash", role: .destructive) { app.delete(deadline) }
        }
    }

    private func newDeadline() -> Deadline {
        let calendar = Week.calendar
        let day = calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: .now)) ?? .now
        return Deadline(title: "", kind: .labReport, due: calendar.date(bySettingHour: 23, minute: 59, second: 0, of: day) ?? day)
    }
}

/// One deadline: a check button, the title, the course, and the time that is left.
struct DeadlineRow: View {
    let deadline: Deadline
    let now: Date
    let open: () -> Void
    let toggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button(action: toggle) {
                Image(systemName: deadline.done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(deadline.done ? Palette.accent : Palette.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(deadline.done ? tr("Mark as not handed in") : tr("Mark as handed in"))
            Button(action: open) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(deadline.title)
                        .font(Karla.font(16, .bold))
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 6) {
                        Chip(text: deadline.kind.name)
                        if !deadline.course.isEmpty {
                            Text(deadline.course)
                                .font(Karla.font(14))
                                .foregroundStyle(Palette.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    Text(due)
                        .font(Karla.font(14, .semibold))
                        .foregroundStyle(isLate ? Palette.danger : Palette.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .card()
    }

    private var isLate: Bool { !deadline.done && deadline.due < now }

    private var due: String {
        let date = deadline.due.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(L10n.locale))
        let time = "\(date), \(Clock.text(deadline.due))"
        if deadline.done { return time }
        if isLate { return tr("Late: %@", time) }
        let calendar = Week.calendar
        if calendar.isDate(deadline.due, inSameDayAs: now) {
            return tr("Today, %@", Clock.text(deadline.due)) + "  ·  " + Countdown.until(deadline.due, from: now)
        }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: deadline.due)).day ?? 0
        return time + "  ·  " + (days == 1 ? tr("Tomorrow") : tr("In %d days", days))
    }
}

extension Deadline.Kind {
    var name: String {
        switch self {
        case .labReport: tr("Lab report")
        case .assignment: tr("Assignment")
        case .other: tr("Other")
        }
    }
}
