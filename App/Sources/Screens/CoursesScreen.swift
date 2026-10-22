import PolyCore
import SwiftUI

/// The courses of the timetable and of the grades, each with its attendance.
struct CoursesScreen: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        Group {
            if app.courseNames.isEmpty {
                EmptyMessage(text: tr("Import your timetable or add a course in Grades. Each course then has a page here."))
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(app.courseNames, id: \.self) { name in
                            NavigationLink { CourseScreen(course: name) } label: { CourseCard(name: name) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(gutter)
                }
            }
        }
        .polyScreen()
        .navigationTitle(tr("Courses"))
    }
}

/// One course in the list, with its attendance.
private struct CourseCard: View {
    @Environment(AppModel.self) private var app
    let name: String

    var body: some View {
        let summary = app.data.attendanceSummary(for: name)
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(Karla.font(16, .bold))
                    .multilineTextAlignment(.leading)
                Text(AttendanceText.line(summary))
                    .font(Karla.font(14))
                    .foregroundStyle(summary.canMiss < 0 ? Palette.danger : Palette.textSecondary)
                let links = app.data.links.filter { $0.course == name }.count
                if links > 0 {
                    Text(links == 1 ? tr("1 quick link") : tr("%d quick links", links))
                        .font(Karla.font(13))
                        .foregroundStyle(Palette.textSecondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Palette.textSecondary)
        }
        .card()
    }
}

enum AttendanceText {
    /// "6 of 8 classes · 75%", or "No marks yet".
    static func line(_ summary: AttendanceSummary) -> String {
        guard let rate = summary.rate else { return tr("No marks yet") }
        return tr("At %d of %d classes", summary.present, summary.present + summary.absent)
            + "  ·  " + rate.formatted(.percent.precision(.fractionLength(0)).locale(L10n.locale))
    }

    /// "You can miss 3 more classes", or a warning over the limit.
    static func canMiss(_ summary: AttendanceSummary) -> String {
        if summary.planned == 0 { return tr("The timetable has no class of this course.") }
        if summary.canMiss < 0 { return tr("%d classes over the limit", -summary.canMiss) }
        if summary.canMiss == 0 { return tr("You cannot miss another class.") }
        return summary.canMiss == 1 ? tr("You can miss 1 more class.") : tr("You can miss %d more classes.", summary.canMiss)
    }
}
