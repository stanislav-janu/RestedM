import Foundation

/// Reads headers from text such as a copied request or a curl `-H` list: one "Name: value" per line.
public enum HeaderText {
    public static func rows(from text: String) -> [KeyValueRow] {
        text.split(whereSeparator: \.isNewline).compactMap { line in
            guard let colon = line.firstIndex(of: ":") else {
                return nil
            }
            let name = line[..<colon].trimmingCharacters(in: .whitespaces)
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            // A header name is one token: no spaces, and never a URL like "https://…".
            guard !name.isEmpty, !name.contains(" "), !value.hasPrefix("//") else {
                return nil
            }
            return KeyValueRow(name: name, value: value)
        }
    }
}
