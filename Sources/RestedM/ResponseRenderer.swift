import AppKit
import RestedCore

/// Builds the attributed text shown in the response pane.
enum ResponseRenderer {
    private struct Key: Hashable {
        let id: UUID
        let tab: ResponseTab
        let pretty: Bool
        let highlight: Bool
    }

    private static var cache: [Key: NSAttributedString] = [:]
    private static let highlightLimit = 2_000_000

    static let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    static let boldFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold)

    static func render(_ exchange: HTTPExchange, tab: ResponseTab, pretty: Bool, highlight: Bool) -> NSAttributedString {
        let key = Key(id: exchange.id, tab: tab, pretty: pretty, highlight: highlight)
        if let cached = cache[key] {
            return cached
        }
        let result: NSAttributedString
        switch tab {
        case .body:
            result = renderBody(exchange, pretty: pretty, highlight: highlight)
        case .headers:
            result = renderHeaders(exchange.responseHeaders, firstLine: exchange.statusLine.map { "HTTP \($0)" } ?? exchange.errorMessage)
        case .request:
            result = renderRequest(exchange, pretty: pretty, highlight: highlight)
        }
        if cache.count > 24 {
            cache.removeAll()
        }
        cache[key] = result
        return result
    }

    private static func renderBody(_ exchange: HTTPExchange, pretty: Bool, highlight: Bool) -> NSAttributedString {
        if exchange.response == nil {
            return plain(exchange.errorMessage ?? "")
        }
        guard let text = exchange.bodyText else {
            return plain("<\(exchange.body.count) bytes of binary data, \(exchange.contentType.isEmpty ? "unknown type" : exchange.contentType)>", color: .secondaryLabelColor)
        }
        return formatted(text, contentType: exchange.contentType, pretty: pretty, highlight: highlight)
    }

    private static func renderRequest(_ exchange: HTTPExchange, pretty: Bool, highlight: Bool) -> NSAttributedString {
        let output = NSMutableAttributedString()
        output.append(NSAttributedString(string: "\(exchange.method) \(exchange.url.absoluteString)\n", attributes: [.font: boldFont, .foregroundColor: NSColor.labelColor]))
        output.append(renderHeaders(exchange.requestHeaders, firstLine: nil))
        if let body = exchange.requestBodyText {
            output.append(plain("\n"))
            let type = exchange.requestHeaders.first { $0.name.caseInsensitiveCompare("Content-Type") == .orderedSame }?.value ?? ""
            output.append(formatted(body, contentType: type.lowercased(), pretty: false, highlight: highlight))
        }
        return output
    }

    private static func renderHeaders(_ headers: [(name: String, value: String)], firstLine: String?) -> NSAttributedString {
        let output = NSMutableAttributedString()
        if let firstLine {
            output.append(NSAttributedString(string: firstLine + "\n", attributes: [.font: boldFont, .foregroundColor: NSColor.labelColor]))
        }
        for header in headers {
            output.append(NSAttributedString(string: header.name, attributes: [.font: boldFont, .foregroundColor: NSColor.systemBlue]))
            output.append(plain(": \(header.value)\n"))
        }
        return output
    }

    static func formatted(_ text: String, contentType: String, pretty: Bool, highlight: Bool) -> NSAttributedString {
        var display = text
        var isJSON = false
        if contentType.contains("json") || contentType.contains("javascript") || JSONPrettyPrinter.isJSON(text) {
            if let formatted = JSONPrettyPrinter.format(text) {
                isJSON = true
                if pretty {
                    display = formatted
                }
            }
        } else if pretty, contentType.contains("xml"), let document = try? XMLDocument(xmlString: text, options: []) {
            display = document.xmlString(options: [.nodePrettyPrint])
        }
        let output = NSMutableAttributedString(string: display, attributes: [.font: font, .foregroundColor: NSColor.labelColor])
        if highlight, isJSON, (display as NSString).length <= highlightLimit {
            JSONHighlighter.apply(to: output)
        }
        return output
    }

    private static func plain(_ text: String, color: NSColor = .labelColor) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
    }
}

enum JSONHighlighter {
    private static let string = try! NSRegularExpression(pattern: #""(?:[^"\\]|\\.)*""#)
    private static let key = try! NSRegularExpression(pattern: #""(?:[^"\\]|\\.)*"(?=\s*:)"#)
    private static let number = try! NSRegularExpression(pattern: #"-?\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b"#)
    private static let literal = try! NSRegularExpression(pattern: #"\b(?:true|false|null)\b"#)

    static func apply(to text: NSMutableAttributedString) {
        let range = NSRange(location: 0, length: text.length)
        let source = text.string
        color(number, .systemOrange, in: text, source: source, range: range)
        color(literal, .systemPink, in: text, source: source, range: range)
        color(string, .systemGreen, in: text, source: source, range: range)
        color(key, .systemPurple, in: text, source: source, range: range)
    }

    private static func color(_ expression: NSRegularExpression, _ color: NSColor, in text: NSMutableAttributedString, source: String, range: NSRange) {
        for match in expression.matches(in: source, range: range) {
            text.addAttribute(.foregroundColor, value: color, range: match.range)
        }
    }
}
