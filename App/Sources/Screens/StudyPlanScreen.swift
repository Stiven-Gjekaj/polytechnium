import PolyCore
import SwiftUI

/// The revision of the exams, day by day.
struct StudyPlanScreen: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        TimelineView(.everyMinute) { context in
            let plan = app.data.studyPlan(at: context.date)
            List {
                Section {
                    Stepper(value: perDay, in: 1...12, step: 0.5) {
                        LabeledContent(tr("Hours each day"), value: Self.hours(app.data.studyHoursPerDay ?? StudyPlan.defaultHoursPerDay))
                    }
                    Stepper(value: days, in: 1...30) {
                        LabeledContent(tr("Days before an exam"), value: String(app.data.studyDays ?? StudyPlan.defaultDays))
                    }
                } footer: {
                    Text(tr("Each exam has its hours of revision in the exam. The exams that come first get their hours first."))
                }
                .listRowBackground(Palette.surface)
                ForEach(plan.short.sorted { $0.key.uuidString < $1.key.uuidString }, id: \.key) { id, hours in
                    if let exam = app.data.exams.first(where: { $0.id == id }) {
                        Text(tr("%@ hours of %@ do not fit. Start earlier, or study more each day.", Self.hours(hours), exam.course))
                            .foregroundStyle(Palette.danger)
                            .listRowBackground(Palette.surface)
                    }
                }
                if plan.blocks.isEmpty {
                    Text(tr("No revision to plan. Add an exam to come."))
                        .foregroundStyle(Palette.textSecondary)
                        .listRowBackground(Palette.surface)
                }
                ForEach(Self.days(of: plan), id: \.self) { day in
                    Section(Self.title(day, now: context.date)) {
                        ForEach(plan.blocks(on: day)) { StudyRow(block: $0) }
                    }
                    .listRowBackground(Palette.surface)
                }
            }
            .polyForm()
        }
        .polyScreen()
        .navigationTitle(tr("Study plan"))
    }

    private var perDay: Binding<Double> {
        Binding(get: { app.data.studyHoursPerDay ?? StudyPlan.defaultHoursPerDay }, set: { value in app.update { $0.studyHoursPerDay = value } })
    }

    private var days: Binding<Int> {
        Binding(get: { app.data.studyDays ?? StudyPlan.defaultDays }, set: { value in app.update { $0.studyDays = value } })
    }

    static func days(of plan: StudyPlan) -> [Date] {
        Array(Set(plan.blocks.map(\.day))).sorted()
    }

    /// "Today", "Tomorrow", or "Monday 11 January".
    static func title(_ day: Date, now: Date) -> String {
        let calendar = L10n.calendar
        if calendar.isDate(day, inSameDayAs: now) { return tr("Today") }
        if let next = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(day, inSameDayAs: next) { return tr("Tomorrow") }
        return day.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(L10n.locale))
    }

    /// "1.5 h".
    static func hours(_ value: Double) -> String {
        tr("%@ h", value.formatted(.number.precision(.fractionLength(0...1)).locale(L10n.locale)))
    }
}

/// One block of revision, with a check.
struct StudyRow: View {
    @Environment(AppModel.self) private var app
    let block: StudyBlock

    var body: some View {
        let done = app.isDone(block)
        Button { app.toggle(block) } label: {
            HStack(spacing: 12) {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(done ? Palette.accent : Palette.textSecondary)
                Text(block.course)
                    .font(Karla.font(16, .semibold))
                    .strikethrough(done)
                Spacer()
                Text(StudyPlanScreen.hours(block.hours))
                    .font(Karla.font(15, .bold))
            }
            .foregroundStyle(Palette.textPrimary)
        }
        .buttonStyle(.plain)
        .accessibilityValue(done ? tr("Done") : "")
    }
}
