import Foundation
import PolyCore

/// The text of the values of the core package, in the chosen language.
extension SessionKind {
    var name: String {
        switch self {
        case .lecture: tr("Lecture")
        case .seminar: tr("Seminar")
        case .lab: tr("Lab")
        case .other: tr("Class")
        }
    }
}

extension WeekParity {
    var name: String {
        switch self {
        case .every: tr("Every week")
        case .odd: tr("Odd weeks")
        case .even: tr("Even weeks")
        }
    }

    /// The name of one week, such as "odd week".
    var weekName: String {
        switch self {
        case .every: tr("Every week")
        case .odd: tr("Odd week")
        case .even: tr("Even week")
        }
    }
}

enum Clock {
    /// "08:00" for 480 minutes. The faculty writes the time with 24 hours.
    static func text(_ minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }

    /// "08:00" for a date.
    static func text(_ date: Date) -> String {
        let parts = L10n.calendar.dateComponents([.hour, .minute], from: date)
        return text((parts.hour ?? 0) * 60 + (parts.minute ?? 0))
    }

    /// "08:00 - 09:00".
    static func range(_ start: Int, _ end: Int) -> String {
        "\(text(start)) - \(text(end))"
    }
}

enum Weekdays {
    /// The name of a day, with 1 for Monday, such as "Monday" or "e hënë".
    static func name(_ weekday: Int) -> String {
        let symbols = L10n.calendar.standaloneWeekdaySymbols
        // The symbols of the calendar start on Sunday.
        let name = symbols[weekday % 7]
        return name.prefix(1).uppercased() + name.dropFirst()
    }

    /// A short name, such as "Mon" or "Hën".
    static func short(_ weekday: Int) -> String {
        let name = L10n.calendar.shortStandaloneWeekdaySymbols[weekday % 7]
        return name.prefix(1).uppercased() + name.dropFirst()
    }
}
