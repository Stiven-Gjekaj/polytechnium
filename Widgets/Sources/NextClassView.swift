import PolyCore
import SwiftUI
import WidgetKit

/// The text of the widget for each size.
struct NextClassView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NextClassEntry

    /// The class to show: the class that is on, or else the next class.
    private var shown: (occurrence: Occurrence, isNow: Bool)? {
        if let current = entry.today?.current { return (current, true) }
        if let next = entry.today?.next { return (next, false) }
        return nil
    }

    var body: some View {
        Group {
            switch family {
            case .accessoryInline: inline
            case .accessoryCircular: circular
            case .accessoryRectangular: rectangular
            case .systemMedium: medium
            default: small
            }
        }
        .environment(\.locale, L10n.locale)
    }

    // MARK: - Lock screen

    private var inline: some View {
        Group {
            if let shown {
                Text(Self.line(shown.occurrence))
            } else {
                Text(entry.today == nil ? tr("No timetable") : tr("No class soon"))
            }
        }
    }

    private var circular: some View {
        VStack(spacing: 0) {
            if let shown {
                Text(Clock.text(shown.isNow ? shown.occurrence.end : shown.occurrence.start))
                    .font(.system(size: 13, weight: .bold))
                Text(shown.occurrence.session.room.isEmpty ? "-" : shown.occurrence.session.room)
                    .font(.system(size: 11))
            } else {
                Image(systemName: "calendar")
            }
        }
        .widgetAccentable()
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let shown {
                Text(shown.isNow ? tr("Now") : tr("Next class"))
                    .font(.system(size: 12, weight: .semibold))
                    .widgetAccentable()
                Text(shown.occurrence.session.course)
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(1)
                Text(Self.place(shown.occurrence, isNow: shown.isNow))
                    .font(.system(size: 13))
                    .lineLimit(1)
            } else {
                Text(entry.today == nil ? tr("No timetable") : tr("No class soon"))
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Home screen

    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let shown {
                Text(shown.isNow ? tr("Now") : tr("Next class"))
                    .font(Karla.font(12, .bold))
                    .foregroundStyle(Palette.textSecondary)
                    .textCase(.uppercase)
                Text(shown.occurrence.session.course)
                    .font(Karla.font(17, .bold))
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                Chip(text: shown.occurrence.session.kind.name, filled: shown.occurrence.session.kind == .lecture)
                Text(Self.place(shown.occurrence, isNow: shown.isNow))
                    .font(Karla.font(13, .semibold))
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(2)
            } else {
                empty
            }
        }
        .foregroundStyle(Palette.textPrimary)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var medium: some View {
        HStack(alignment: .top, spacing: 14) {
            small
            if let next = mediumSecond {
                Rectangle().fill(Palette.outline).frame(width: 1)
                VStack(alignment: .leading, spacing: 4) {
                    Text(tr("Then"))
                        .font(Karla.font(12, .bold))
                        .foregroundStyle(Palette.textSecondary)
                        .textCase(.uppercase)
                    Text(next.session.course)
                        .font(Karla.font(15, .bold))
                        .lineLimit(3)
                    Spacer(minLength: 0)
                    Text(Self.place(next, isNow: false))
                        .font(Karla.font(13, .semibold))
                        .foregroundStyle(Palette.textSecondary)
                        .lineLimit(2)
                }
                .foregroundStyle(Palette.textPrimary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    /// The class after the one in the first half of the medium widget.
    private var mediumSecond: Occurrence? {
        guard let today = entry.today else { return nil }
        return today.current != nil ? today.next : today.later.first
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "calendar")
                .font(.system(size: 20))
            Text(entry.today == nil ? tr("Import your timetable in the app.") : tr("No class in the next two weeks."))
                .font(Karla.font(14, .semibold))
                .foregroundStyle(Palette.textSecondary)
        }
    }

    // MARK: - Text

    /// "Room 110 · 10:00", or "Room 110 · until 11:00" for the class that is on.
    static func place(_ occurrence: Occurrence, isNow: Bool) -> String {
        var parts: [String] = []
        if !occurrence.session.room.isEmpty { parts.append(tr("Room %@", occurrence.session.room)) }
        parts.append(isNow ? tr("until %@", Clock.text(occurrence.end)) : startText(occurrence.start))
        return parts.joined(separator: " · ")
    }

    /// "10:00" today, or "Mon 10:00" on another day.
    static func startText(_ start: Date) -> String {
        let calendar = L10n.calendar
        if calendar.isDateInToday(start) { return Clock.text(start) }
        return "\(Weekdays.short(Week.weekday(of: start, calendar: calendar))) \(Clock.text(start))"
    }

    /// "Elektroteknika 2, 110, 10:00".
    static func line(_ occurrence: Occurrence) -> String {
        [occurrence.session.course, occurrence.session.room, startText(occurrence.start)]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}
