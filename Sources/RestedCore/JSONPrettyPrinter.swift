import Foundation

/// Re-indents JSON text without parsing it into dictionaries, so key order is kept.
public enum JSONPrettyPrinter {
    /// Starts like a JSON object or array, whether or not it parses.
    public static func looksLikeJSON(_ text: String) -> Bool {
        guard let first = text.first(where: { !$0.isWhitespace }) else {
            return false
        }
        return first == "{" || first == "["
    }

    public static func isJSON(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first, first == "{" || first == "[" else {
            return false
        }
        return (try? JSONSerialization.jsonObject(with: Data(trimmed.utf8), options: [.fragmentsAllowed])) != nil
    }

    /// Why text that should be JSON is not: nil when it parses, otherwise the 1-based line of
    /// the first error when the parser names one (0 when it does not).
    public static func errorLine(in text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        do {
            _ = try JSONSerialization.jsonObject(with: Data(text.utf8), options: [.fragmentsAllowed])
            return nil
        } catch {
            let description = (error as NSError).userInfo[NSDebugDescriptionErrorKey] as? String ?? ""
            let pattern = try! NSRegularExpression(pattern: #"line (\d+)"#)
            let range = NSRange(description.startIndex..., in: description)
            guard let match = pattern.firstMatch(in: description, range: range),
                  let lineRange = Range(match.range(at: 1), in: description) else {
                return 0
            }
            return Int(description[lineRange]) ?? 0
        }
    }

    public static func format(_ text: String, indent: String = "  ") -> String? {
        guard isJSON(text) else {
            return nil
        }
        let scalars = Array(text.unicodeScalars)
        let indentScalars = Array(indent.unicodeScalars)
        var out = String.UnicodeScalarView()
        var level = 0
        var inString = false
        var escaped = false
        var index = 0

        func newline() {
            out.append("\n")
            for _ in 0..<max(level, 0) {
                out.append(contentsOf: indentScalars)
            }
        }

        while index < scalars.count {
            let scalar = scalars[index]
            if inString {
                out.append(scalar)
                if escaped {
                    escaped = false
                } else if scalar == "\\" {
                    escaped = true
                } else if scalar == "\"" {
                    inString = false
                }
                index += 1
                continue
            }
            switch scalar {
            case "\"":
                inString = true
                out.append(scalar)
            case "{", "[":
                let close: Unicode.Scalar = scalar == "{" ? "}" : "]"
                var next = index + 1
                while next < scalars.count, isWhitespace(scalars[next]) {
                    next += 1
                }
                if next < scalars.count, scalars[next] == close {
                    out.append(scalar)
                    out.append(close)
                    index = next + 1
                    continue
                }
                out.append(scalar)
                level += 1
                newline()
            case "}", "]":
                level -= 1
                newline()
                out.append(scalar)
            case ",":
                out.append(scalar)
                newline()
            case ":":
                out.append(scalar)
                out.append(" ")
            case " ", "\t", "\n", "\r":
                break
            default:
                out.append(scalar)
            }
            index += 1
        }
        return String(out)
    }

    public static func quote(_ string: String) -> String {
        var out = "\""
        for scalar in string.unicodeScalars {
            switch scalar {
            case "\"":
                out += "\\\""
            case "\\":
                out += "\\\\"
            case "\n":
                out += "\\n"
            case "\r":
                out += "\\r"
            case "\t":
                out += "\\t"
            case _ where scalar.value < 0x20:
                out += String(format: "\\u%04x", scalar.value)
            default:
                out.unicodeScalars.append(scalar)
            }
        }
        return out + "\""
    }

    private static func isWhitespace(_ scalar: Unicode.Scalar) -> Bool {
        scalar == " " || scalar == "\t" || scalar == "\n" || scalar == "\r"
    }
}
