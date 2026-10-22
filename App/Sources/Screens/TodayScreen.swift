import PolyCore
import SwiftUI

/// The class that is on now, the next class, and the rest of the day.
struct TodayScreen: View {
    @Environment(AppModel.self) private var app
    @State private var settings = false

    var body: some View {
        NavigationStack {
            TimelineView(.everyMinute) { context in
                if let timetable = app.timetable, !timetable.sessions.isEmpty {
                    content(app.week.today(in: timetable, at: context.date), now: context.date)
                } else {
                    EmptyMessage(text: tr("Import your timetable in the Timetable tab. Then this screen shows your next class."))
                }
            }
            .polyScreen()
            .navigationTitle(tr("Today"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { settings = true } label: {
                        Image(systemName: "gearshape")
                            .accessibilityLabel(tr("Settings"))
                    }
                }
            }
            .sheet(isPresented: $settings) { SettingsScreen() }
        }
    }

    private func content(_ today: Today, now: Date) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(dateLine(now))
                    .font(Karla.font(15, .semibold))
                    .foregroundStyle(Palette.textSecondary)

                SectionTitle(text: tr("Now"))
                if let current = today.current {
                    NowCard(occurrence: current, progress: today.progress(at: now), left: Countdown.left(current.end, from: now))
                } else {
                    Text(tr("No class now."))
                        .font(Karla.font(15))
                        .foregroundStyle(Palette.textSecondary)
                        .card()
                }

                SectionTitle(text: tr("Next"))
                    .padding(.top, 6)
                if let next = today.next {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Countdown.when(next.start, from: now))
                            .font(Karla.font(15, .bold))
                        ClassRow(session: next.session)
                    }
                } else {
                    Text(tr("No class in the next two weeks."))
                        .font(Karla.font(15))
                        .foregroundStyle(Palette.textSecondary)
                        .card()
                }

                if !today.later.isEmpty {
                    SectionTitle(text: tr("Later today"))
                        .padding(.top, 6)
                    ForEach(today.later) { ClassRow(session: $0.session) }
                }
                attendanceQuestion(now: now)
                studyToday(now: now)
                comingUp(now: now)
            }
            .padding(gutter)
        }
    }

    /// A question for each class of today that is over and has no mark of attendance.
    @ViewBuilder
    private func attendanceQuestion(now: Date) -> some View {
        let ended = app.data.unmarked(on: now)
        if !ended.isEmpty {
            SectionTitle(text: tr("Were you there?"))
                .padding(.top, 6)
            ForEach(ended) { occurrence in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(occurrence.session.course)
                            .font(Karla.font(15, .bold))
                        Text("\(occurrence.session.kind.name)  ·  \(Clock.range(occurrence.session.start, occurrence.session.end))")
                            .font(Karla.font(13))
                            .foregroundStyle(Palette.textSecondary)
                    }
                    Spacer(minLength: 4)
                    Button { mark(occurrence, present: true) } label: {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.polyPrimary)
                    .accessibilityLabel(tr("I was there"))
                    Button { mark(occurrence, present: false) } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.polySecondary)
                    .accessibilityLabel(tr("I missed it"))
                }
                .card()
            }
        }
    }

    private func mark(_ occurrence: Occurrence, present: Bool) {
        app.mark(occurrence.session.course, kind: occurrence.session.kind, on: occurrence.start, present: present)
    }

    /// The revision of today, from the study plan.
    @ViewBuilder
    private func studyToday(now: Date) -> some View {
        let blocks = app.data.studyPlan(at: now).blocks(on: now)
        if !blocks.isEmpty {
            SectionTitle(text: tr("Study today"))
                .padding(.top, 6)
            VStack(spacing: 10) {
                ForEach(blocks) { StudyRow(block: $0) }
            }
            .card()
        }
    }

    /// The next exam in 30 days, and the deadlines in the next 7 days that are not handed in.
    @ViewBuilder
    private func comingUp(now: Date) -> some View {
        let exam = app.data.exams.first { (0...30).contains($0.daysLeft(from: now)) }
        let week = now.addingTimeInterval(7 * 86400)
        let deadlines = app.data.deadlines.filter { !$0.done && $0.due < week }
        if exam != nil || !deadlines.isEmpty {
            SectionTitle(text: tr("Coming up"))
                .padding(.top, 6)
            if let exam { ExamRow(exam: exam, now: now) }
            ForEach(deadlines) { deadline in
                DeadlineRow(deadline: deadline, now: now, open: {}) {
                    var changed = deadline
                    changed.done = true
                    app.save(changed)
                }
            }
        }
    }

    /// "Thursday, 22 October · odd week".
    private func dateLine(_ now: Date) -> String {
        let date = now.formatted(.dateTime.day().month(.wide).locale(L10n.locale))
        let day = Weekdays.name(Week.weekday(of: now))
        return "\(day), \(date)  ·  \(app.week.parity(of: now).weekName.lowercased())"
    }
}

/// The class that is on, with a bar of the time that is over.
struct NowCard: View {
    let occurrence: Occurrence
    let progress: Double
    let left: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Chip(text: occurrence.session.kind.name, filled: true)
                Spacer()
                Text(left)
                    .font(Karla.font(14, .semibold))
                    .foregroundStyle(Palette.textSecondary)
            }
            Text(occurrence.session.course)
                .font(Karla.font(22, .bold, relativeTo: .title2))
            HStack(spacing: 16) {
                if !occurrence.session.room.isEmpty {
                    Label(occurrence.session.room, systemImage: "door.left.hand.open")
                }
                if !occurrence.session.lecturer.isEmpty {
                    Label(occurrence.session.lecturer, systemImage: "person")
                }
            }
            .font(Karla.font(15))
            .foregroundStyle(Palette.textSecondary)
            ProgressView(value: progress)
                .tint(Palette.accent)
                .accessibilityLabel(tr("Time of the class that is over"))
            HStack {
                Text(Clock.text(occurrence.start))
                Spacer()
                Text(Clock.text(occurrence.end))
            }
            .font(Karla.font(13))
            .foregroundStyle(Palette.textSecondary)
        }
        .card()
    }
}
