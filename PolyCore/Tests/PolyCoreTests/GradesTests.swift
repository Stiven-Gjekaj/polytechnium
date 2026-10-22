import Testing
@testable import PolyCore

private let scale = GradeScale.standard

/// Elektroteknika 2 with a midterm of 30%, labs of 20%, and a final of 50%.
private func course(midterm: Double? = nil, labs: Double? = nil, final: Double? = nil, credits: Double = 6) -> CourseGrade {
    CourseGrade(name: "Elektroteknika 2", credits: credits, components: [
        GradeComponent(name: "Midterm", weight: 30, score: midterm),
        GradeComponent(name: "Labs", weight: 20, score: labs),
        GradeComponent(name: "Final", weight: 50, score: final),
    ])
}

@Test func theScaleGivesEachGrade() {
    #expect(scale.grade(for: 100) == 10)
    #expect(scale.grade(for: 91) == 10)
    #expect(scale.grade(for: 90.9) == 9)
    #expect(scale.grade(for: 71) == 8)
    #expect(scale.grade(for: 41) == 5)
    #expect(scale.grade(for: 40.9) == 4)
    #expect(scale.grade(for: 0) == 4)
}

@Test func aCompleteCourseHasTheGradeOfItsPoints() {
    // 0.3 * 80 + 0.2 * 90 + 0.5 * 70 = 77 points.
    let full = course(midterm: 80, labs: 90, final: 70)
    #expect(abs(full.points - 77) < 0.0001)
    #expect(full.grade(on: scale) == 8)
}

@Test func aCourseWithAPartToDoHasNoGrade() {
    #expect(course(midterm: 80, labs: 90).grade(on: scale) == nil)
}

@Test func theGradeOfTheFacultyComesFirst() {
    var given = course(midterm: 80, labs: 90, final: 70)
    given.finalGrade = 9
    #expect(given.grade(on: scale) == 9)
}

@Test func theFinalNeedsTheMissingPointsForAnEight() {
    // 24 + 18 = 42 points so far. An 8 needs 71, so the final needs 29 of 50: 58 points.
    #expect(course(midterm: 80, labs: 90).needed(for: 8, on: scale) == .needs(average: 58))
}

@Test func twoPartsToDoNeedTheSameAverage() {
    // 24 points so far. A 7 needs 61, so 37 of the 70 that are left: 52.9 points on average.
    #expect(course(midterm: 80).needed(for: 7, on: scale) == .needs(average: 52.9))
}

@Test func aGradeThatThePointsGiveIsSecured() {
    #expect(course(midterm: 100, labs: 100).needed(for: 5, on: scale) == .secured)
}

@Test func aGradeOverTheBestThatIsPossibleIsImpossible() {
    // 6 + 4 = 10 points so far, and at most 60 with 100 on the final: a 6.
    #expect(course(midterm: 20, labs: 20).needed(for: 9, on: scale) == .impossible(best: 6))
}

@Test func weightsThatDoNotGiveOneHundredCountInTheirShare() {
    // Two parts of 40% each: a total of 80%. 60 points of 100 on the first is 24 of 80.
    let partial = CourseGrade(name: "Fizikë", credits: 5, components: [
        GradeComponent(name: "Midterm", weight: 40, score: 60),
        GradeComponent(name: "Final", weight: 40),
    ])
    // A 7 needs 61% of 80 = 48.8, so the final needs 24.8 of 40: 62 points.
    #expect(partial.needed(for: 7, on: scale) == .needs(average: 62))
}

@Test func theAverageIsWeightedByTheCredits() throws {
    let courses = [
        CourseGrade(name: "A", credits: 6, finalGrade: 10),
        CourseGrade(name: "B", credits: 4, finalGrade: 7),
        CourseGrade(name: "C", credits: 5, finalGrade: 4),
        CourseGrade(name: "D", credits: 5),
    ]
    let average = try #require(GradeAverage(courses, scale: scale))
    // (10 * 6 + 7 * 4) / 10 = 8.8. The failed course and the course with no grade do not count.
    #expect(abs(average.value - 8.8) < 0.0001)
    #expect(average.credits == 10)
}

@Test func noGradeGivesNoAverage() {
    #expect(GradeAverage([CourseGrade(name: "A", credits: 6)], scale: scale) == nil)
}
