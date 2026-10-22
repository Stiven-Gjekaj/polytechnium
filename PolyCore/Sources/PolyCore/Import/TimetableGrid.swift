import CoreGraphics
import Foundation

/// One word of a page, with its place in the text of the page.
public struct Glyph: Equatable, Sendable {
    /// The place of the word in the text of the page. The words of one cell
    /// come in this order.
    public var index: Int
    public var text: String
    public var center: CGPoint

    public init(index: Int, text: String, center: CGPoint) {
        self.index = index
        self.text = text
        self.center = center
    }
}

/// The classes of each group, from the borders and the words of a timetable page.
///
/// The page has one row of column names at the top. "ORA" names a column of
/// hours, such as "08:00", and the other names are groups, such as "II-A-ELN".
/// The hours start again at the top of each day, from Monday to Friday. A merged
/// cell has no border inside it, so a lecture for four groups is one cell that
/// covers four columns.
public struct TimetableGrid: Sendable {
    /// The groups in the order of the page, from left to right.
    public private(set) var groups: [String] = []
    /// The classes of each group.
    public private(set) var sessions: [String: [ClassSession]] = [:]

    public init(rects: [FilledRect], glyphs: [Glyph]) {
        let lines = Lines(rects)
        guard let headerWord = glyphs.first(where: { $0.text == "ORA" }) else { return }

        // The row of column names lies between the two lines around "ORA".
        let headerY = headerWord.center.y
        let headerTop = lines.horizontal(above: headerY, at: headerWord.center.x) ?? headerY + 8
        let headerBottom = lines.horizontal(below: headerY, at: headerWord.center.x) ?? headerY - 8
        let edges = lines.verticalEdges(at: headerY)
        guard edges.count > 1 else { return }

        var columns: [Column] = []
        for (left, right) in zip(edges, edges.dropFirst()) where right - left > 2 {
            let words = glyphs.filter {
                left < $0.center.x && $0.center.x < right && headerBottom < $0.center.y && $0.center.y < headerTop
            }
            let name = Self.normalized(Self.joined(words))
            guard !name.isEmpty else { continue }
            columns.append(Column(name: name, left: left, right: right))
        }

        // Each part of the page starts with a column of hours. A group uses the
        // rows of the hour column to its left.
        var parts: [(hours: Column, groups: [Column], rows: [Row])] = []
        for column in columns {
            if column.name == "ORA" {
                let rows = Self.rows(of: column, lines: lines, glyphs: glyphs, below: headerBottom)
                parts.append((column, [], rows))
            } else if column.name != "DITA", !parts.isEmpty {
                parts[parts.count - 1].groups.append(column)
            }
        }
        groups = Self.unique(parts.flatMap { $0.groups.map(\.name) })

        var found: [String: [ClassSession]] = [:]
        for part in parts {
            var seen = Set<[Int]>()
            for start in part.groups.indices {
                for first in part.rows.indices {
                    let cell = Self.cell(from: start, row: first, part.groups, part.rows, lines)
                    guard seen.insert([cell.columns.lowerBound, cell.columns.upperBound, cell.rows.lowerBound, cell.rows.upperBound]).inserted
                    else { continue }
                    let box = CGRect(
                        x: part.groups[cell.columns.lowerBound].left,
                        y: part.rows[cell.rows.upperBound].bottom,
                        width: part.groups[cell.columns.upperBound].right - part.groups[cell.columns.lowerBound].left,
                        height: part.rows[cell.rows.lowerBound].top - part.rows[cell.rows.upperBound].bottom
                    )
                    let text = Self.joined(glyphs.filter { box.contains($0.center) })
                    let top = part.rows[cell.rows.lowerBound], bottom = part.rows[cell.rows.upperBound]
                    guard top.weekday == bottom.weekday else { continue }
                    for entry in Self.entries(text) {
                        for column in cell.columns {
                            found[part.groups[column].name, default: []].append(ClassSession(
                                course: entry.course, kind: entry.kind, weekday: top.weekday,
                                start: top.start, end: bottom.start + bottom.length,
                                room: entry.room, lecturer: entry.lecturer, parity: entry.parity
                            ))
                        }
                    }
                }
            }
        }
        sessions = found.mapValues(Self.merged)
    }

    /// Adds the groups and the classes of another page.
    mutating func add(_ other: TimetableGrid) {
        groups = Self.unique(groups + other.groups)
        for (group, classes) in other.sessions {
            sessions[group] = Self.merged(sessions[group, default: []] + classes)
        }
    }

    /// The timetable of one group.
    public func timetable(for group: String) -> Timetable {
        Timetable(group: group, sessions: sessions[group] ?? [])
    }

    // MARK: - Borders

    /// The thin black rectangles of a page, which are the borders of the cells.
    struct Lines {
        var vertical: [(x: CGFloat, low: CGFloat, high: CGFloat)] = []
        var horizontal: [(y: CGFloat, low: CGFloat, high: CGFloat)] = []

        init(_ rects: [FilledRect]) {
            for fill in rects where TimetableGrid.isDark(fill.color) {
                let rect = fill.rect
                if rect.width < 1, rect.height >= 5 {
                    vertical.append((rect.midX, rect.minY, rect.maxY))
                } else if rect.height < 1, rect.width >= 5 {
                    horizontal.append((rect.midY, rect.minX, rect.maxX))
                }
            }
        }

        /// A vertical border at `x` that crosses the height `y`.
        func hasVertical(x: CGFloat, y: CGFloat) -> Bool {
            vertical.contains { abs($0.x - x) < 0.8 && $0.low - 0.5 <= y && y <= $0.high + 0.5 }
        }

        /// A horizontal border at `y` that crosses the place `x`.
        func hasHorizontal(y: CGFloat, x: CGFloat) -> Bool {
            horizontal.contains { abs($0.y - y) < 0.8 && $0.low - 0.5 <= x && x <= $0.high + 0.5 }
        }

        /// The places of the vertical borders that cross the height `y`, left to right.
        func verticalEdges(at y: CGFloat) -> [CGFloat] {
            TimetableGrid.distinct(vertical.filter { $0.low - 0.5 <= y && y <= $0.high + 0.5 }.map(\.x))
        }

        /// The heights of the horizontal borders that cross the place `x`, top to bottom.
        func horizontalEdges(at x: CGFloat) -> [CGFloat] {
            TimetableGrid.distinct(horizontal.filter { $0.low - 0.5 <= x && x <= $0.high + 0.5 }.map(\.y)).reversed()
        }

        func horizontal(above y: CGFloat, at x: CGFloat) -> CGFloat? {
            horizontalEdges(at: x).last { $0 > y + 0.5 }
        }

        func horizontal(below y: CGFloat, at x: CGFloat) -> CGFloat? {
            horizontalEdges(at: x).first { $0 < y - 0.5 }
        }
    }

    /// The values in order, with the values nearer than 0.8 to the one before as one.
    static func distinct(_ values: [CGFloat]) -> [CGFloat] {
        var result: [CGFloat] = []
        for value in values.sorted() where result.last.map({ value - $0 >= 0.8 }) ?? true {
            result.append(value)
        }
        return result
    }

    // MARK: - Columns and rows

    struct Column {
        var name: String
        var left: CGFloat
        var right: CGFloat
        var mid: CGFloat { (left + right) / 2 }
    }

    struct Row {
        var top: CGFloat
        var bottom: CGFloat
        var weekday: Int
        var start: Int
        var length: Int
        var mid: CGFloat { (top + bottom) / 2 }
    }

    /// The rows of an hour column, top to bottom. A row with no hour, such as the
    /// gap between two days, is not a row. A day ends where the hours start again.
    static func rows(of column: Column, lines: Lines, glyphs: [Glyph], below header: CGFloat) -> [Row] {
        let edges = lines.horizontalEdges(at: column.mid).filter { $0 <= header + 0.5 }
        var rows: [Row] = []
        var weekday = 1
        for (top, bottom) in zip(edges, edges.dropFirst()) {
            let words = glyphs.filter {
                column.left < $0.center.x && $0.center.x < column.right && bottom < $0.center.y && $0.center.y < top
            }
            guard let start = minutes(in: joined(words)) else { continue }
            if let previous = rows.last, start <= previous.start { weekday += 1 }
            rows.append(Row(top: top, bottom: bottom, weekday: weekday, start: start, length: 60))
        }
        // A row lasts until the next row of the same day.
        for index in rows.indices.dropLast() where rows[index + 1].weekday == rows[index].weekday {
            rows[index].length = rows[index + 1].start - rows[index].start
        }
        return rows
    }

    /// The minutes after midnight of an hour such as "08:00" or "8.00".
    static func minutes(in text: String) -> Int? {
        let parts = text.split(whereSeparator: { $0 == ":" || $0 == "." })
        guard parts.count == 2, parts[1].count == 2,
              let hour = Int(parts[0]), let minute = Int(parts[1]),
              (0..<24).contains(hour), (0..<60).contains(minute)
        else { return nil }
        return hour * 60 + minute
    }

    /// The columns and the rows of the cell at one column and one row. The cell
    /// goes on to the next column or row while no border is between them.
    static func cell(
        from column: Int, row: Int, _ columns: [Column], _ rows: [Row], _ lines: Lines
    ) -> (columns: ClosedRange<Int>, rows: ClosedRange<Int>) {
        let y = rows[row].mid
        var low = column, high = column
        while low > 0, !lines.hasVertical(x: columns[low].left, y: y) { low -= 1 }
        while high < columns.count - 1, !lines.hasVertical(x: columns[high].right, y: y) { high += 1 }

        let x = (columns[low].left + columns[high].right) / 2
        var top = row, bottom = row
        while top > 0, rows[top - 1].bottom == rows[top].top || abs(rows[top - 1].bottom - rows[top].top) < 0.8,
              !lines.hasHorizontal(y: rows[top].top, x: x) { top -= 1 }
        while bottom < rows.count - 1, abs(rows[bottom + 1].top - rows[bottom].bottom) < 0.8,
              !lines.hasHorizontal(y: rows[bottom].bottom, x: x) { bottom += 1 }
        return (low...high, top...bottom)
    }

    // MARK: - Text

    /// The words in the order of the text of the page.
    static func joined(_ glyphs: [Glyph]) -> String {
        glyphs.sorted { $0.index < $1.index }.map(\.text).joined(separator: " ")
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// The classes in the text of one cell. A cell can hold two classes, such as
    /// one for the odd weeks and one for the even weeks, each with its own mark.
    static func entries(_ text: String) -> [CellText] {
        let marked = text.replacingOccurrences(
            of: #"\((?:S|L|s|l|Lab|LAB|lab)\)"#, with: "\u{1F}$0", options: .regularExpression
        )
        return marked.split(separator: "\u{1F}").compactMap { CellText(String($0)) }
    }

    static func isDark(_ color: [CGFloat]) -> Bool {
        color.count >= 3 && color[0] < 0.3 && color[1] < 0.3 && color[2] < 0.3
    }

    /// "II-A- ELN" becomes "II-A-ELN", and "II-SIST  ELN" becomes "II-SIST ELN".
    static func normalized(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
            .replacingOccurrences(of: #"\s*-\s*"#, with: "-", options: .regularExpression)
    }

    // MARK: - Classes

    /// Joins a class of one hour with the same class in the next hour.
    ///
    /// A cell with no mark that comes after the same course gets the kind of
    /// that course, because the timetable writes the mark only in the first hour.
    static func merged(_ sessions: [ClassSession]) -> [ClassSession] {
        var result: [ClassSession] = []
        let sorted = sessions.sorted { ($0.weekday, $0.start, $0.course) < ($1.weekday, $1.start, $1.course) }
        for var session in sorted {
            if session.kind == .other, let before = result.last(where: {
                $0.weekday == session.weekday && $0.end == session.start && $0.course == session.course
            }) {
                session.kind = before.kind
            }
            if let index = result.lastIndex(where: {
                $0.weekday == session.weekday && $0.end == session.start && $0.sameClass(as: session)
            }) {
                result[index].end = session.end
            } else if !result.contains(where: {
                $0.weekday == session.weekday && $0.start == session.start && $0.sameClass(as: session)
            }) {
                result.append(session)
            }
        }
        return result
    }

    static func unique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }
}
