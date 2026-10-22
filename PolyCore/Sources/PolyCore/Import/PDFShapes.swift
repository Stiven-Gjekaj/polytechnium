import CoreGraphics
import Foundation

/// A filled rectangle on a page, in the space of the page, with its fill colour.
public struct FilledRect: Equatable, Sendable {
    public var rect: CGRect
    /// The red, green, and blue parts of the fill, each from 0 to 1.
    public var color: [CGFloat]

    public init(rect: CGRect, color: [CGFloat]) {
        self.rect = rect
        self.color = color
    }
}

/// Reads the filled rectangles of a PDF page. A spreadsheet that is printed to a
/// PDF draws the fill of each cell as one rectangle, so the rectangles give the
/// cells, also the merged cells.
enum PDFShapes {
    static func filledRects(of page: CGPDFPage) -> [FilledRect] {
        let collector = ShapeCollector()
        guard let table = CGPDFOperatorTableCreate() else { return [] }
        register(table)
        let stream = CGPDFContentStreamCreateWithPage(page)
        let scanner = CGPDFScannerCreate(stream, table, Unmanaged.passUnretained(collector).toOpaque())
        CGPDFScannerScan(scanner)
        CGPDFScannerRelease(scanner)
        CGPDFContentStreamRelease(stream)
        CGPDFOperatorTableRelease(table)
        return collector.rects
    }

    private static func register(_ table: CGPDFOperatorTableRef) {
        CGPDFOperatorTableSetCallback(table, "q") { _, info in
            guard let c = collector(info) else { return }
            c.stack.append((c.ctm, c.fill))
        }
        CGPDFOperatorTableSetCallback(table, "Q") { _, info in
            guard let c = collector(info), let state = c.stack.popLast() else { return }
            c.ctm = state.0
            c.fill = state.1
        }
        CGPDFOperatorTableSetCallback(table, "cm") { scanner, info in
            guard let c = collector(info), let n = numbers(scanner, 6) else { return }
            c.ctm = CGAffineTransform(a: n[0], b: n[1], c: n[2], d: n[3], tx: n[4], ty: n[5]).concatenating(c.ctm)
        }
        CGPDFOperatorTableSetCallback(table, "rg") { scanner, info in
            guard let c = collector(info), let n = numbers(scanner, 3) else { return }
            c.fill = n
        }
        CGPDFOperatorTableSetCallback(table, "g") { scanner, info in
            guard let c = collector(info), let n = numbers(scanner, 1) else { return }
            c.fill = [n[0], n[0], n[0]]
        }
        CGPDFOperatorTableSetCallback(table, "k") { scanner, info in
            guard let c = collector(info), let n = numbers(scanner, 4) else { return }
            c.fill = [(1 - n[0]) * (1 - n[3]), (1 - n[1]) * (1 - n[3]), (1 - n[2]) * (1 - n[3])]
        }
        CGPDFOperatorTableSetCallback(table, "re") { scanner, info in
            guard let c = collector(info), let n = numbers(scanner, 4) else { return }
            c.closeSubpath()
            c.subpaths.append([
                CGPoint(x: n[0], y: n[1]), CGPoint(x: n[0] + n[2], y: n[1]),
                CGPoint(x: n[0] + n[2], y: n[1] + n[3]), CGPoint(x: n[0], y: n[1] + n[3]),
            ].map { $0.applying(c.ctm) })
        }
        CGPDFOperatorTableSetCallback(table, "m") { scanner, info in
            guard let c = collector(info), let n = numbers(scanner, 2) else { return }
            c.closeSubpath()
            c.current = [CGPoint(x: n[0], y: n[1]).applying(c.ctm)]
        }
        CGPDFOperatorTableSetCallback(table, "l") { scanner, info in
            guard let c = collector(info), let n = numbers(scanner, 2) else { return }
            c.current.append(CGPoint(x: n[0], y: n[1]).applying(c.ctm))
        }
        CGPDFOperatorTableSetCallback(table, "h") { _, info in
            collector(info)?.closeSubpath()
        }
        for fill in ["f", "F", "f*", "B", "B*", "b", "b*"] {
            CGPDFOperatorTableSetCallback(table, fill) { _, info in
                collector(info)?.fillPath()
            }
        }
        for end in ["n", "S", "s"] {
            CGPDFOperatorTableSetCallback(table, end) { _, info in
                collector(info)?.dropPath()
            }
        }
    }
}

private func collector(_ info: UnsafeMutableRawPointer?) -> ShapeCollector? {
    guard let info else { return nil }
    return Unmanaged<ShapeCollector>.fromOpaque(info).takeUnretainedValue()
}

private func numbers(_ scanner: CGPDFScannerRef, _ count: Int) -> [CGFloat]? {
    var values: [CGFloat] = []
    for _ in 0..<count {
        var value: CGPDFReal = 0
        guard CGPDFScannerPopNumber(scanner, &value) else { return nil }
        values.append(value)
    }
    return values.reversed()
}

/// The state of the scan. The scanner calls back on the same thread, one
/// operator at a time.
private final class ShapeCollector {
    var ctm = CGAffineTransform.identity
    var fill: [CGFloat] = [0, 0, 0]
    var stack: [(CGAffineTransform, [CGFloat])] = []
    var subpaths: [[CGPoint]] = []
    var current: [CGPoint] = []
    var rects: [FilledRect] = []

    func closeSubpath() {
        if !current.isEmpty { subpaths.append(current) }
        current = []
    }

    func fillPath() {
        closeSubpath()
        for points in subpaths {
            if let rect = Self.axisRect(points) {
                rects.append(FilledRect(rect: rect, color: fill))
            }
        }
        subpaths = []
    }

    func dropPath() {
        current = []
        subpaths = []
    }

    /// The rectangle of a path of four corners with straight sides, or nil for another shape.
    static func axisRect(_ points: [CGPoint]) -> CGRect? {
        var corners = points
        if corners.count == 5, corners.first == corners.last { corners.removeLast() }
        guard corners.count == 4 else { return nil }
        let xs = Set(corners.map { ($0.x * 10).rounded() })
        let ys = Set(corners.map { ($0.y * 10).rounded() })
        guard xs.count <= 2, ys.count <= 2 else { return nil }
        let minX = corners.map(\.x).min()!, maxX = corners.map(\.x).max()!
        let minY = corners.map(\.y).min()!, maxY = corners.map(\.y).max()!
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
