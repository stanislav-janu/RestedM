import RestedCore
import SwiftUI

/// User defaults keys, named as in Rested's Defaults.plist.
enum Preferences {
    static let timeout = "timeoutLengthInSeconds"
    static let allowSelfSigned = "allowSelfSignedCertificates"
    static let useCookies = "useCookies"
    static let prettifySentJSON = "prettifySentJSON"
    static let prettyPrint = "prettyPrint"
    static let highlightSyntax = "highlightSyntax"
    static let lineNumbers = "includeLineNumbers"
    static let paramBodyUIChoice = "paramBodyUIChoice"
    static let defaultResponseTab = "defaultResponseTab"

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            timeout: 10,
            allowSelfSigned: false,
            useCookies: false,
            prettifySentJSON: false,
            prettyPrint: true,
            highlightSyntax: true,
            lineNumbers: false,
            paramBodyUIChoice: 0,
            defaultResponseTab: ResponseTab.body.rawValue,
        ])
    }

    static var sendOptions: SendOptions {
        let defaults = UserDefaults.standard
        return SendOptions(
            timeout: TimeInterval(max(defaults.integer(forKey: timeout), 1)),
            useCookies: defaults.bool(forKey: useCookies),
            prettifySentJSON: defaults.bool(forKey: prettifySentJSON)
        )
    }

    static var allowsInvalidCertificates: Bool {
        UserDefaults.standard.bool(forKey: allowSelfSigned)
    }
}

/// Which parts of the request editor are visible below the headers.
enum ParamBodyLayout: Int, CaseIterable, Identifiable {
    case both = 0
    case parameters = 1
    case body = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .both:
            return "Parameters & Body"
        case .parameters:
            return "Parameters"
        case .body:
            return "HTTP Body"
        }
    }
}

enum ResponseTab: Int, CaseIterable, Identifiable {
    case body = 0
    case headers = 1
    case request = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .body:
            return "Response Body"
        case .headers:
            return "Response Headers"
        case .request:
            return "Request"
        }
    }
}

struct PreferencesView: View {
    @AppStorage(Preferences.timeout) private var timeout = 10
    @AppStorage(Preferences.allowSelfSigned) private var allowSelfSigned = false
    @AppStorage(Preferences.useCookies) private var useCookies = false
    @AppStorage(Preferences.prettifySentJSON) private var prettifySentJSON = false
    @AppStorage(Preferences.prettyPrint) private var prettyPrint = true
    @AppStorage(Preferences.highlightSyntax) private var highlightSyntax = true
    @AppStorage(Preferences.lineNumbers) private var lineNumbers = false
    @AppStorage(Preferences.paramBodyUIChoice) private var paramBodyUIChoice = 0
    @AppStorage(Preferences.defaultResponseTab) private var defaultResponseTab = 0

    var body: some View {
        Form {
            Section("Request Settings") {
                LabeledContent("Timeout Interval") {
                    HStack {
                        Slider(value: Binding(get: { Double(timeout) }, set: { timeout = Int($0) }), in: 2...180, step: 1)
                        Text("\(timeout) s")
                            .monospacedDigit()
                            .frame(width: 44, alignment: .trailing)
                    }
                }
                Toggle("Allow self-signed and unverified SSL certificates", isOn: $allowSelfSigned)
                Toggle("Store and send cookies automatically", isOn: $useCookies)
                Toggle("Prettify sent custom JSON bodies", isOn: $prettifySentJSON)
            }
            Section("Response Output Settings") {
                Toggle("Pretty-print response", isOn: $prettyPrint)
                Toggle("Apply syntax highlighting", isOn: $highlightSyntax)
                Toggle("Include line numbers", isOn: $lineNumbers)
                Picker("Default display", selection: $defaultResponseTab) {
                    ForEach(ResponseTab.allCases) { tab in
                        Text(tab.title).tag(tab.rawValue)
                    }
                }
            }
            Section("Default UI") {
                Picker("New documents show", selection: $paramBodyUIChoice) {
                    ForEach(ParamBodyLayout.allCases) { layout in
                        Text(layout.title).tag(layout.rawValue)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 520)
        .fixedSize(horizontal: false, vertical: true)
    }
}
