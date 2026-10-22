import PolyCore
import SwiftUI

/// The credit-weighted average and the grade of each course.
struct GradesScreen: View {
    @Environment(AppModel.self) private var app
    @State private var editing: CourseGrade?

    var body: some View {
        NavigationStack {
            Group {
                if app.data.courses.isEmpty {
                    empty
                } else {
                    content
                }
            }
            .polyScreen()
            .navigationTitle(tr("Grades"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(tr("Add a course"), systemImage: "plus") { editing = newCourse() }
                        if !app.coursesToAdd.isEmpty {
                            Button(tr("Add the courses of the timetable"), systemImage: "calendar") { app.addTimetableCourses() }
                        }
                    } label: {
                        Image(systemName: "plus")
                            .accessibilityLabel(tr("Add"))
                    }
                }
            }
            .sheet(item: $editing) { CourseGradeEditor(course: $0) }
        }
    }

    private var empty: some View {
        VStack(spacing: 0) {
            EmptyMessage(
                text: tr("Add your courses with their credits and the weight of each part, such as the midterm, the labs, and the final."),
                action: app.coursesToAdd.isEmpty ? tr("Add a course") : tr("Add the courses of the timetable")
            ) {
                if app.coursesToAdd.isEmpty { editing = newCourse() } else { app.addTimetableCourses() }
            }
        }
    }

    private var content: some View {
        let scale = app.data.gradeScale
        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                averageCard(GradeAverage(app.data.courses, scale: scale))
                SectionTitle(text: tr("Courses"))
                    .padding(.top, 6)
                ForEach(app.data.courses) { course in
                    Button { editing = course } label: { CourseRow(course: course, scale: scale) }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(tr("Delete"), systemImage: "trash", role: .destructive) { app.delete(course) }
                        }
                }
            }
            .padding(gutter)
        }
    }

    private func averageCard(_ average: GradeAverage?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(tr("Average"))
                .font(Karla.font(13, .bold))
                .foregroundStyle(Palette.textSecondary)
                .textCase(.uppercase)
            Text(average.map { $0.value.formatted(.number.precision(.fractionLength(2)).locale(L10n.locale)) } ?? "-")
                .font(Karla.font(44, .bold, relativeTo: .largeTitle))
            Text(average.map { tr("Weighted by %@ credits of passed courses", Self.number($0.credits)) }
                ?? tr("A course counts when it has a grade of 5 or more and its credits."))
                .font(Karla.font(14))
                .foregroundStyle(Palette.textSecondary)
        }
        .card()
        .accessibilityElement(children: .combine)
    }

    private func newCourse() -> CourseGrade {
        CourseGrade(name: "", credits: 6, components: [
            GradeComponent(name: tr("Midterm"), weight: 40),
            GradeComponent(name: tr("Final exam"), weight: 60),
        ])
    }

    /// "6" for 6.0, and "7.5" for 7.5.
    static func number(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)).locale(L10n.locale))
    }
}

/// One course: the name, the credits, and the grade or the points so far.
struct CourseRow: View {
    let course: CourseGrade
    let scale: GradeScale

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(course.name)
                    .font(Karla.font(16, .bold))
                    .multilineTextAlignment(.leading)
                Text(detail)
                    .font(Karla.font(14))
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer(minLength: 8)
            Text(course.grade(on: scale).map(String.init) ?? "-")
                .font(Karla.font(28, .bold, relativeTo: .title))
                .frame(minWidth: 40)
        }
        .card()
        .accessibilityElement(children: .combine)
    }

    private var detail: String {
        let credits = tr("%@ credits", GradesScreen.number(course.credits))
        guard course.grade(on: scale) == nil, course.doneWeight > 0 else { return credits }
        return credits + "  ·  " + tr("%@ of %@ points so far", GradesScreen.number(course.points), GradesScreen.number(course.doneWeight))
    }
}
