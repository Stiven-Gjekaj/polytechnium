import PolyCore
import SwiftUI

/// The exams of the session, with the days that are left to each one.
struct ExamsScreen: View {
    @Environment(AppModel.self) private var app
    @State private var editing: Exam?

    var body: some View {
        NavigationStack {
            TimelineView(.everyMinute) { context in
                if app.data.exams.isEmpty {
                    EmptyMessage(
                        text: tr("Add the exams of the session. The app counts the days and reminds you one week, three days, and one day before."),
                        action: tr("Add an exam")
                    ) { editing = newExam() }
                } else {
                    content(now: context.date)
                }
            }
            .polyScreen()
            .navigationTitle(tr("Exams"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { editing = newExam() } label: {
                        Image(systemName: "plus")
                            .accessibilityLabel(tr("Add an exam"))
                    }
                }
            }
            .sheet(item: $editing) { ExamEditor(exam: $0) }
        }
    }

    private func content(now: Date) -> some View {
        let upcoming = app.data.exams.filter { $0.daysLeft(from: now) >= 0 }
        let past = app.data.exams.filter { $0.daysLeft(from: now) < 0 }
        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if upcoming.isEmpty {
                    Text(tr("No exam to come."))
                        .font(Karla.font(15))
                        .foregroundStyle(Palette.textSecondary)
                        .card()
                }
                ForEach(upcoming) { exam in
                    row(exam, now: now)
                }
                if !past.isEmpty {
                    SectionTitle(text: tr("Past exams"))
                        .padding(.top, 8)
                    ForEach(past.reversed()) { exam in
                        row(exam, now: now)
                            .opacity(0.45)
                    }
                }
            }
            .padding(gutter)
        }
    }

    private func row(_ exam: Exam, now: Date) -> some View {
        Button { editing = exam } label: { ExamRow(exam: exam, now: now) }
            .buttonStyle(.plain)
            .contextMenu {
                Button(tr("Delete"), systemImage: "trash", role: .destructive) { app.delete(exam) }
            }
    }

    private func newExam() -> Exam {
        let calendar = Week.calendar
        let start = calendar.date(byAdding: .day, value: 14, to: calendar.startOfDay(for: .now)) ?? .now
        return Exam(course: "", date: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: start) ?? start)
    }
}

/// One exam: the days that are left, the course, the date, and the room.
struct ExamRow: View {
    let exam: Exam
    let now: Date

    var body: some View {
        let days = exam.daysLeft(from: now)
        HStack(spacing: 16) {
            VStack(spacing: 0) {
                Text(days >= 0 ? String(days) : "-")
                    .font(Karla.font(30, .bold, relativeTo: .title))
                Text(days == 1 ? tr("day") : tr("days"))
                    .font(Karla.font(12, .semibold))
                    .foregroundStyle(Palette.textSecondary)
            }
            .frame(width: 60)
            VStack(alignment: .leading, spacing: 4) {
                Text(exam.course)
                    .font(Karla.font(16, .bold))
                    .multilineTextAlignment(.leading)
                Text(when(days))
                    .font(Karla.font(14, .semibold))
                Text(details)
                    .font(Karla.font(14))
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer(minLength: 0)
            if exam.remind {
                Image(systemName: "bell")
                    .foregroundStyle(Palette.textSecondary)
                    .accessibilityLabel(tr("Reminders are on"))
            }
        }
        .card()
        .accessibilityElement(children: .combine)
    }

    private func when(_ days: Int) -> String {
        switch days {
        case 0: tr("Today, %@", Clock.text(exam.date))
        case 1: tr("Tomorrow, %@", Clock.text(exam.date))
        default: tr("In %d days", days)
        }
    }

    private var details: String {
        let date = exam.date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(L10n.locale))
        let parts = [date + ", " + Clock.text(exam.date)] + (exam.room.isEmpty ? [] : [tr("Room %@", exam.room)])
        return parts.joined(separator: "  ·  ")
    }
}
