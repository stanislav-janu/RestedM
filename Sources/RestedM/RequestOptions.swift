import RestedCore
import SwiftUI

/// Text Encoding and Follow Redirects, shown in the toolbar options menu and the Request menu.
struct RequestOptionsMenuContent: View {
    @Binding var request: RestRequest

    var body: some View {
        Picker("Text Encoding", selection: $request.stringEncoding) {
            ForEach(TextEncodingChoice.choices(including: request.stringEncoding)) { choice in
                Text(choice.title).tag(choice.rawValue)
            }
        }
        .pickerStyle(.menu)
        Toggle("Follow Redirects", isOn: $request.followRedirects)
    }
}

struct TextEncodingChoice: Identifiable {
    let rawValue: UInt
    let title: String

    var id: UInt {
        rawValue
    }

    static let standard = [
        TextEncodingChoice(rawValue: String.Encoding.utf8.rawValue, title: "UTF-8"),
        TextEncodingChoice(rawValue: String.Encoding.isoLatin1.rawValue, title: "ISO Latin-1"),
        TextEncodingChoice(rawValue: String.Encoding.ascii.rawValue, title: "ASCII"),
    ]

    /// The standard encodings, plus the one a RESTed document uses when it is another.
    static func choices(including current: UInt) -> [TextEncodingChoice] {
        if standard.contains(where: { $0.rawValue == current }) {
            return standard
        }
        let name = String.localizedName(of: String.Encoding(rawValue: current))
        return standard + [TextEncodingChoice(rawValue: current, title: name.isEmpty ? "Encoding \(current)" : name)]
    }
}

struct RequestKey: FocusedValueKey {
    typealias Value = Binding<RestRequest>
}

extension FocusedValues {
    /// The request of the key window, for Request menu commands that change it.
    var request: Binding<RestRequest>? {
        get { self[RequestKey.self] }
        set { self[RequestKey.self] = newValue }
    }
}
