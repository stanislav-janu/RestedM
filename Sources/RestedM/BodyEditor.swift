import AppKit
import RestedCore
import SwiftUI

/// Editable monospaced text view for the HTTP body: JSON highlighting with the response colors,
/// and no smart quotes, dashes, spelling or autocorrection, so the body is sent exactly as typed.
struct BodyEditor: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.drawsBackground = false
        scrollView.autohidesScrollers = true
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.font = ResponseRenderer.font
        textView.textColor = .labelColor
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: Space.xs, height: Space.sm)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.smartInsertDeleteEnabled = false
        textView.setAccessibilityLabel("HTTP Body")
        textView.string = text
        context.coordinator.highlight(textView)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = scrollView.documentView as? NSTextView, textView.string != text else {
            return
        }
        textView.string = text
        context.coordinator.highlight(textView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: BodyEditor

        init(parent: BodyEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }
            // Only typing writes to the document, so opening a request never marks it edited.
            parent.text = textView.string
            highlight(textView)
        }

        func highlight(_ textView: NSTextView) {
            guard let storage = textView.textStorage else {
                return
            }
            let range = NSRange(location: 0, length: storage.length)
            storage.beginEditing()
            storage.setAttributes([.font: ResponseRenderer.font, .foregroundColor: NSColor.labelColor], range: range)
            if JSONPrettyPrinter.looksLikeJSON(textView.string) {
                JSONHighlighter.apply(to: storage)
            }
            storage.endEditing()
        }
    }
}
