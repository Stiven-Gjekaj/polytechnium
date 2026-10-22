import Foundation

/// One part of the grade of a course, such as the midterm, the labs, or the final.
public struct GradeComponent: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    /// The part of the course grade, in percent.
    public var weight: Double
    /// The points of the part, from 0 to 100. Nil when the part is not done yet.
    public var score: Double?

    public init(id: UUID = UUID(), name: String, weight: Double, score: Double? = nil) {
        self.id = id
        self.name = name
        self.weight = weight
        self.score = score
    }
}

/// A course with its credits and the parts of its grade.
public struct CourseGrade: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var credits: Double
    public var components: [GradeComponent]
    /// The grade from 4 to 10 that the faculty gave. It takes the place of the
    /// grade from the points.
    public var finalGrade: Int?

    public init(id: UUID = UUID(), name: String, credits: Double, components: [GradeComponent] = [], finalGrade: Int? = nil) {
        self.id = id
        self.name = name
        self.credits = credits
        self.components = components
        self.finalGrade = finalGrade
    }

    /// The sum of the weights of all parts, in percent.
    public var totalWeight: Double { components.map(\.weight).reduce(0, +) }

    /// The sum of the weights of the parts that have points.
    public var doneWeight: Double { components.filter { $0.score != nil }.map(\.weight).reduce(0, +) }

    /// The points that the parts with points give to the course, from 0 to 100.
    public var points: Double {
        components.compactMap { part in part.score.map { $0 * part.weight / 100 } }.reduce(0, +)
    }

    /// True when each part has points.
    public var isComplete: Bool { !components.isEmpty && components.allSatisfy { $0.score != nil } }

    /// The grade of the course: the grade of the faculty, or the grade of the
    /// points when each part has points.
    public func grade(on scale: GradeScale) -> Int? {
        if let finalGrade { return finalGrade }
        return isComplete ? scale.grade(for: points / max(totalWeight, 1) * 100) : nil
    }

    /// The points that the parts with no points need for a grade.
    public func needed(for target: Int, on scale: GradeScale) -> Need {
        guard let minimum = scale.minimum(for: target) else { return .impossible(best: nil) }
        let remaining = totalWeight - doneWeight
        guard totalWeight > 0 else { return .noParts }
        // The scale is for 100 points, so the parts count in their share of the total weight.
        let goal = minimum * totalWeight / 100
        if points >= goal { return .secured }
        guard remaining > 0 else { return .impossible(best: grade(on: scale)) }
        let average = (goal - points) / remaining * 100
        if average > 100 {
            let best = scale.grade(for: (points + remaining) / totalWeight * 100)
            return .impossible(best: best)
        }
        return .needs(average: (average * 10).rounded(.up) / 10)
    }

    /// What the parts with no points need for a grade.
    public enum Need: Hashable, Sendable {
        /// The points so far give the grade already.
        case secured
        /// The parts with no points need this average, from 0 to 100.
        case needs(average: Double)
        /// Even 100 points in each part with no points do not give the grade.
        /// `best` is the best grade that is possible.
        case impossible(best: Int?)
        /// The course has no parts.
        case noParts
    }
}

/// The grades from 4 to 10 and the lowest points for each one.
public struct GradeScale: Codable, Hashable, Sendable {
    /// The lowest points for each grade from 5 to 10. Less than the points for 5 gives 4.
    public var minimums: [Int: Double]

    public init(minimums: [Int: Double]) {
        self.minimums = minimums
    }

    /// The scale of the universities of Albania: 91 points give 10, 81 give 9,
    /// and so on to 41 points for 5.
    public static let standard = GradeScale(minimums: [10: 91, 9: 81, 8: 71, 7: 61, 6: 51, 5: 41])

    public func grade(for points: Double) -> Int {
        // A rounding of the points, so that 90.999 is not less than 91.
        let rounded = (points * 1000).rounded() / 1000
        return minimums.filter { rounded >= $0.value }.map(\.key).max() ?? 4
    }

    /// The lowest points for a grade. A grade of 4 needs no points.
    public func minimum(for grade: Int) -> Double? {
        grade == 4 ? 0 : minimums[grade]
    }
}

/// The average of the courses, weighted by their credits.
public struct GradeAverage: Hashable, Sendable {
    public var value: Double
    /// The credits of the courses in the average.
    public var credits: Double

    /// The average of the passed courses. A course with a grade of 4 is not
    /// passed, and a course with no grade is not in the average. Nil when no
    /// course counts.
    public init?(_ courses: [CourseGrade], scale: GradeScale) {
        let counted = courses.compactMap { course in
            course.grade(on: scale).flatMap { $0 >= 5 && course.credits > 0 ? ($0, course.credits) : nil }
        }
        let credits = counted.map(\.1).reduce(0, +)
        guard credits > 0 else { return nil }
        value = counted.map { Double($0.0) * $0.1 }.reduce(0, +) / credits
        self.credits = credits
    }
}
