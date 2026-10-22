import PolyCore
import SwiftUI
import WidgetKit

@main
struct PolytechniumWidgets: WidgetBundle {
    var body: some Widget {
        NextClassWidget()
    }
}

/// The class that is on, or the next class, on the home screen and the lock screen.
struct NextClassWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextClass", provider: NextClassProvider()) { entry in
            NextClassView(entry: entry)
                .containerBackground(Palette.background, for: .widget)
        }
        .configurationDisplayName(tr("Next class"))
        .description(tr("The class that is on now, or your next class, with the room and the time."))
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline, .accessoryCircular])
    }
}

struct NextClassEntry: TimelineEntry {
    let date: Date
    /// Nil when there is no timetable.
    let today: Today?
}

struct NextClassProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextClassEntry {
        NextClassEntry(date: .now, today: Self.sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextClassEntry) -> Void) {
        let entry = Self.entries(from: .now).first
        completion(context.isPreview && entry?.today == nil ? placeholder(in: context) : entry ?? placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextClassEntry>) -> Void) {
        let entries = Self.entries(from: .now)
        // After the last entry, WidgetKit asks for a new timeline.
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    /// One entry now, and one at each start and end of a class in the next day.
    static func entries(from now: Date) -> [NextClassEntry] {
        guard let data = try? AppGroup.store.load(), let timetable = data.timetable, !timetable.sessions.isEmpty else {
            return [NextClassEntry(date: now, today: nil)]
        }
        let week = data.weekOrDefault(at: now)
        let end = now.addingTimeInterval(24 * 3600)
        let moments = [now] + week.changes(in: timetable, from: now, to: end)
        var entries = moments.map { NextClassEntry(date: $0, today: week.today(in: timetable, at: $0)) }
        if moments.count == 1 {
            // A day with no change still needs a new timeline the next day.
            entries.append(NextClassEntry(date: end, today: week.today(in: timetable, at: end)))
        }
        return entries
    }

    static let sample: Today = {
        let start = Date.now.addingTimeInterval(25 * 60)
        let session = ClassSession(
            course: "Elektroteknika 2", kind: .seminar, weekday: 1, start: 600, end: 660, room: "110", lecturer: "L. Gjini"
        )
        return Today(current: nil, next: Occurrence(session: session, start: start, end: start.addingTimeInterval(3600)), later: [])
    }()
}
