import CoreGraphics
import CoreText
import Foundation
@testable import PolyCore

/// A small timetable in the form of the faculty timetable, which a test builds
/// in memory or draws into a PDF.
///
/// The columns are "ORA" and three groups. The rows are three hours on Monday,
/// a gap row, and two hours on Tuesday.
struct TimetableDrawing {
    struct Cell {
        var columns: ClosedRange<Int>
        var rows: ClosedRange<Int>
        var text: String
    }

    static let names = ["ORA", "II-A-ELN", "II-B-ELN", "II-C-ELN"]
    static let hours = ["08:00", "09:00", "10:00", "", "08:00", "09:00"]
    static let columnWidth: CGFloat = 200
    static let rowHeight: CGFloat = 16
    static let width = columnWidth * CGFloat(names.count) + 40
    static let height = rowHeight * CGFloat(hours.count + 1) + 40

    /// The cells of the classes. Column 1 is the first group, and row 0 is 08:00 on Monday.
    var classes: [Cell]

    /// Each cell of the page: the names, the hours, the classes, and an empty
    /// cell in each other place.
    var allCells: [Cell] {
        var cells = Self.names.indices.map { Cell(columns: $0...$0, rows: -1...(-1), text: Self.names[$0]) }
        cells += Self.hours.indices.map { Cell(columns: 0...0, rows: $0...$0, text: Self.hours[$0]) }
        cells += classes
        for row in Self.hours.indices {
            for column in 1..<Self.names.count
            where !classes.contains(where: { $0.columns.contains(column) && $0.rows.contains(row) }) {
                cells.append(Cell(columns: column...column, rows: row...row, text: ""))
            }
        }
        return cells
    }

    /// The box of a cell, in the space of a PDF page, with the origin at the bottom.
    static func box(_ cell: Cell) -> CGRect {
        let left = 20 + CGFloat(cell.columns.lowerBound) * columnWidth
        let top = height - 20 - CGFloat(cell.rows.lowerBound + 1) * rowHeight
        return CGRect(
            x: left, y: top - CGFloat(cell.rows.count) * rowHeight,
            width: CGFloat(cell.columns.count) * columnWidth, height: CGFloat(cell.rows.count) * rowHeight
        )
    }

    /// The four borders of each cell, as thin black rectangles.
    var borders: [FilledRect] {
        allCells.flatMap { cell -> [FilledRect] in
            let box = Self.box(cell)
            return [
                CGRect(x: box.minX, y: box.minY, width: 0.2, height: box.height),
                CGRect(x: box.maxX, y: box.minY, width: 0.2, height: box.height),
                CGRect(x: box.minX, y: box.minY, width: box.width, height: 0.2),
                CGRect(x: box.minX, y: box.maxY, width: box.width, height: 0.2),
            ].map { FilledRect(rect: $0, color: [0, 0, 0]) }
        }
    }

    /// The words of each cell, on one line in the middle of the cell.
    var glyphs: [Glyph] {
        var glyphs: [Glyph] = []
        for cell in allCells {
            let box = Self.box(cell)
            for (offset, word) in cell.text.split(separator: " ").enumerated() {
                glyphs.append(Glyph(
                    index: glyphs.count * 2,
                    text: String(word),
                    center: CGPoint(x: box.minX + 10 + CGFloat(offset) * 8, y: box.midY)
                ))
            }
        }
        return glyphs
    }

    /// A PDF of one page with the borders and the text, as a spreadsheet prints it.
    var pdf: Data {
        let data = NSMutableData()
        var media = CGRect(x: 0, y: 0, width: Self.width, height: Self.height)
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &media, nil)
        else { return Data() }
        context.beginPDFPage(nil)
        context.setFillColor(CGColor(red: 0.8, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 20, y: 20, width: Self.width - 40, height: Self.height - 40))
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        for border in borders { context.fill(border.rect) }
        let font = CTFontCreateWithName("Helvetica" as CFString, 5, nil)
        for cell in allCells where !cell.text.isEmpty {
            let box = Self.box(cell)
            let text = NSAttributedString(string: cell.text, attributes: [.init(kCTFontAttributeName as String): font])
            let line = CTLineCreateWithAttributedString(text)
            context.textPosition = CGPoint(x: box.minX + 4, y: box.midY - 1.5)
            CTLineDraw(line, context)
        }
        context.endPDFPage()
        context.closePDF()
        return data as Data
    }
}
