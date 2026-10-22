import Foundation

/// The parts of the text of one timetable cell, such as
/// "(S) Teori Sinjali I. Shinko 206 cift".
public struct CellText: Equatable, Sendable {
    public var course: String
    public var kind: SessionKind
    public var room: String
    public var lecturer: String
    public var parity: WeekParity

    /// Reads the text of a cell. A text with no course gives nil.
    public init?(_ text: String) {
        var words = text
            .replacingOccurrences(of: "(", with: " (")
            .replacingOccurrences(of: ")", with: ") ")
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)

        kind = .other
        if let first = words.first?.lowercased(), first.hasPrefix("("), first.hasSuffix(")") {
            switch first {
            case "(l)": kind = .lecture
            case "(s)": kind = .seminar
            case "(lab)": kind = .lab
            default: break
            }
            words.removeFirst()
        }

        parity = .every
        var rooms: [String] = []
        var rest: [String] = []
        var index = 0
        while index < words.count {
            let word = words[index]
            let folded = Self.fold(word)
            if folded == "lab", index + 1 < words.count, let room = Self.room(words[index + 1]) {
                // "LAB 108" is a room, not the kind of the class.
                rooms.append("LAB " + room)
                index += 2
                continue
            }
            if folded == "tek" {
                parity = .odd
            } else if folded == "cift" {
                parity = .even
            } else if folded == "lab" {
                kind = .lab
            } else if let room = Self.room(word) {
                rooms.append(room)
            } else {
                rest.append(word)
            }
            index += 1
        }

        let (course, lecturer) = Self.splitLecturer(rest)
        guard !course.isEmpty else { return nil }
        self.course = course
        self.lecturer = lecturer
        room = rooms.joined(separator: ", ")
    }

    /// A word with no accents and in lower case, so that "Çift" and "cift" agree.
    static func fold(_ word: String) -> String {
        word.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
    }

    /// The room in a word of three or four digits. The timetable sometimes writes
    /// a room two times with no space, such as "115115".
    static func room(_ word: String) -> String? {
        let digits = word.trimmingCharacters(in: CharacterSet(charactersIn: ",.;"))
        guard digits.allSatisfy(\.isNumber), !digits.isEmpty else { return nil }
        if digits.count == 6, digits.prefix(3) == digits.suffix(3) {
            return String(digits.prefix(3))
        }
        return (3...4).contains(digits.count) ? digits : nil
    }

    /// Splits the words at the first name of a lecturer, such as "R. Datja" or
    /// "L.Likaj". The words before it are the course.
    static func splitLecturer(_ words: [String]) -> (course: String, lecturer: String) {
        for (index, word) in words.enumerated() where isInitial(word) || isJoinedName(word) {
            let course = words[..<index].joined(separator: " ")
            guard !course.isEmpty else { continue }
            var name = word
            if isInitial(word), index + 1 < words.count, startsWithCapital(words[index + 1]) {
                name += " " + words[index + 1]
                let after = words[(index + 2)...]
                return (course, ([name] + after).joined(separator: " "))
            }
            if isJoinedName(word) {
                // "L.Likaj" becomes "L. Likaj".
                name = String(word.prefix(2)) + " " + word.dropFirst(2)
            }
            return (course, ([name] + words[(index + 1)...]).joined(separator: " "))
        }
        return (words.joined(separator: " "), "")
    }

    /// A word such as "R." with one capital letter and a full stop.
    static func isInitial(_ word: String) -> Bool {
        word.count == 2 && word.last == "." && startsWithCapital(word)
    }

    /// A word such as "L.Likaj" with an initial and a name and no space.
    static func isJoinedName(_ word: String) -> Bool {
        let parts = Array(word)
        return parts.count > 3 && parts[1] == "." && startsWithCapital(word) && parts[2].isUppercase
    }

    static func startsWithCapital(_ word: String) -> Bool {
        word.first?.isUppercase == true
    }
}
