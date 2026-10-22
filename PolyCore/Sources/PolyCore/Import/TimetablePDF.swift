import CoreGraphics
import Foundation
import PDFKit

/// Reads a timetable of the faculty from a PDF, such as "Orari-Bachelor.pdf".
public enum TimetablePDF {
    public enum Failure: Error, Equatable {
        /// The data is not a PDF.
        case notAPDF
        /// The PDF has no row of group names and hours.
        case noTimetable
    }

    /// The groups and the classes of all pages.
    public static func read(_ data: Data) throws -> TimetableGrid {
        guard let document = PDFDocument(data: data), let provider = CGDataProvider(data: data as CFData),
              let pdf = CGPDFDocument(provider)
        else { throw Failure.notAPDF }
        var grid: TimetableGrid?
        for number in 0..<document.pageCount {
            guard let page = document.page(at: number), let cgPage = pdf.page(at: number + 1) else { continue }
            let pageGrid = TimetableGrid(rects: PDFShapes.filledRects(of: cgPage), glyphs: glyphs(of: page))
            guard !pageGrid.groups.isEmpty else { continue }
            grid = grid.map { $0.adding(pageGrid) } ?? pageGrid
        }
        guard let grid, grid.sessions.values.contains(where: { !$0.isEmpty }) else { throw Failure.noTimetable }
        return grid
    }

    /// The words of a page with the center of each one.
    ///
    /// The place of a word comes from a selection of its range. The bounds of one
    /// character, from `characterBounds(at:)`, move away from the text after the
    /// first lines of a large page.
    static func glyphs(of page: PDFPage) -> [Glyph] {
        guard let string = page.string else { return [] }
        let text = string as NSString
        var glyphs: [Glyph] = []
        var start: Int?
        for index in 0...text.length {
            let isSpace = index == text.length
                || CharacterSet.whitespacesAndNewlines.contains(Unicode.Scalar(text.character(at: index)) ?? " ")
            if !isSpace {
                if start == nil { start = index }
                continue
            }
            guard let first = start else { continue }
            start = nil
            let range = NSRange(location: first, length: index - first)
            guard let bounds = page.selection(for: range)?.bounds(for: page), !bounds.isEmpty else { continue }
            glyphs.append(Glyph(index: first, text: text.substring(with: range), center: CGPoint(x: bounds.midX, y: bounds.midY)))
        }
        return glyphs
    }
}

extension TimetableGrid {
    /// The groups and the classes of two pages together.
    func adding(_ other: TimetableGrid) -> TimetableGrid {
        var result = self
        result.add(other)
        return result
    }
}
