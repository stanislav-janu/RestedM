import AppKit
import SwiftUI

/// Read-only, searchable NSTextView for large response bodies.
struct CodeTextView: NSViewRepresentable {
    let text: NSAttributedString
    let showsLineNumbers: Bool

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        let textView = NSTextView(usingTextLayoutManager: false)
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 6, height: 6)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.minSize = .zero
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.layoutManager?.allowsNonContiguousLayout = true
        scrollView.documentView = textView

        let ruler = LineNumberRulerView(textView: textView)
        scrollView.verticalRulerView = ruler
        scrollView.hasVerticalRuler = true
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else {
            return
        }
        if context.coordinator.shown !== text {
            context.coordinator.shown = text
            textView.textStorage?.setAttributedString(text)
            textView.scrollToBeginningOfDocument(nil)
            (scrollView.verticalRulerView as? LineNumberRulerView)?.textDidChange()
        }
        scrollView.rulersVisible = showsLineNumbers
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var shown: NSAttributedString?
    }
}

final class LineNumberRulerView: NSRulerView {
    private weak var textView: NSTextView?
    private var lineStarts: [Int] = [0]

    init(textView: NSTextView) {
        self.textView = textView
        super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
        clientView = textView
        ruleThickness = 40
        NotificationCenter.default.addObserver(self, selector: #selector(boundsChanged), name: NSView.boundsDidChangeNotification, object: nil)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    @objc private func boundsChanged(_ notification: Notification) {
        if let clip = notification.object as? NSClipView, clip === scrollView?.contentView {
            needsDisplay = true
        }
    }

    func textDidChange() {
        scrollView?.contentView.postsBoundsChangedNotifications = true
        let string = (textView?.string ?? "") as NSString
        var starts = [0]
        var location = 0
        while location < string.length {
            let range = string.range(of: "\n", options: .literal, range: NSRange(location: location, length: string.length - location))
            if range.location == NSNotFound {
                break
            }
            location = range.location + 1
            starts.append(location)
        }
        lineStarts = starts
        let digits = max(String(starts.count).count, 2)
        ruleThickness = CGFloat(digits) * 8 + 16
        needsDisplay = true
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView, let layoutManager = textView.layoutManager, let container = textView.textContainer else {
            return
        }
        NSColor.controlBackgroundColor.setFill()
        bounds.fill()

        let visible = textView.visibleRect
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visible, in: container)
        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular),
            .foregroundColor: NSColor.secondaryLabelColor,
        ]
        let length = (textView.string as NSString).length

        var line = firstLine(atOrBefore: characterRange.location)
        while line < lineStarts.count {
            let start = lineStarts[line]
            if start > NSMaxRange(characterRange) || (start >= length && length > 0) {
                break
            }
            let glyph = layoutManager.glyphIndexForCharacter(at: start)
            let fragment = layoutManager.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
            let y = fragment.minY + textView.textContainerOrigin.y
            let point = convert(NSPoint(x: 0, y: y), from: textView)
            let label = "\(line + 1)" as NSString
            let size = label.size(withAttributes: attributes)
            label.draw(at: NSPoint(x: ruleThickness - size.width - 6, y: point.y + (fragment.height - size.height) / 2), withAttributes: attributes)
            line += 1
        }
    }

    private func firstLine(atOrBefore location: Int) -> Int {
        var low = 0
        var high = lineStarts.count - 1
        while low < high {
            let mid = (low + high + 1) / 2
            if lineStarts[mid] <= location {
                low = mid
            } else {
                high = mid - 1
            }
        }
        return low
    }
}
