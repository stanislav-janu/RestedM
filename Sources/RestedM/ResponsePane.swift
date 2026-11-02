import RestedCore
import SwiftUI

struct ResponsePane: View {
    let exchange: HTTPExchange?
    let buildError: String?
    let isSending: Bool
    @Binding var tab: ResponseTab?

    @AppStorage(Preferences.defaultResponseTab) private var defaultTab = ResponseTab.body.rawValue
    @AppStorage(Preferences.prettyPrint) private var prettyPrint = true
    @AppStorage(Preferences.highlightSyntax) private var highlightSyntax = true
    @AppStorage(Preferences.lineNumbers) private var lineNumbers = false

    private var selectedTab: Binding<ResponseTab> {
        Binding(
            get: { tab ?? ResponseTab(rawValue: defaultTab) ?? .body },
            set: { tab = $0 }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if let buildError, !isSending {
                ContentUnavailableView {
                    Label("Unable to Send Request", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(buildError)
                }
            } else if let exchange {
                summary(exchange)
                Divider()
                HStack(spacing: Space.sm) {
                    Picker("View", selection: selectedTab) {
                        ForEach(ResponseTab.allCases) { tab in
                            Text(tab.title).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    Button {
                        copyShownTab(exchange)
                    } label: {
                        Label("Copy", systemImage: "document.on.document")
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .help("Copy the shown tab as text")
                }
                .padding(.horizontal, Space.pane)
                .padding(.vertical, Space.sm)
                if exchange.response == nil && selectedTab.wrappedValue == .body {
                    ContentUnavailableView {
                        Label(exchange.errorMessage ?? "No Response", systemImage: "xmark.octagon")
                    } description: {
                        Text(NetworkErrorHint.text(for: exchange.errorCode))
                    }
                } else {
                    CodeTextView(
                        text: ResponseRenderer.render(exchange, tab: selectedTab.wrappedValue, pretty: prettyPrint, highlight: highlightSyntax),
                        showsLineNumbers: lineNumbers
                    )
                }
            } else if isSending {
                ProgressView("Waiting for response…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "No Response Yet",
                    systemImage: "paperplane",
                    description: Text("Press ⌘R to send the request.")
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(nsColor: .textBackgroundColor))
        .overlay(alignment: .topTrailing) {
            if isSending && exchange != nil {
                ProgressView()
                    .controlSize(.small)
                    .padding(Space.md)
            }
        }
    }

    private func summary(_ exchange: HTTPExchange) -> some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            HStack(spacing: Space.sm) {
                MethodBadge(method: exchange.method)
                Text(exchange.url.absoluteString)
                    .font(.system(.callout, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }
            HStack(spacing: Space.md) {
                if let status = exchange.statusLine, let code = exchange.response?.statusCode {
                    Text(status)
                        .font(.callout.bold())
                        .foregroundStyle(Palette.status(code))
                } else {
                    Label("No Response", systemImage: "xmark.octagon.fill")
                        .font(.callout.bold())
                        .foregroundStyle(Color(nsColor: StatusColors.serverError))
                }
                Text("Response time: \(formatted(exchange.elapsed))")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                if exchange.response != nil {
                    Text(ByteCountFormatter.string(fromByteCount: Int64(exchange.body.count), countStyle: .file))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.pane)
    }

    private func copyShownTab(_ exchange: HTTPExchange) {
        let text = ResponseRenderer.render(exchange, tab: selectedTab.wrappedValue, pretty: prettyPrint, highlight: false).string
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func formatted(_ interval: TimeInterval) -> String {
        if interval < 1 {
            return "\(Int((interval * 1000).rounded())) ms"
        }
        return String(format: "%.2f s", interval)
    }
}

/// How to fix a failed send, by URLError code.
enum NetworkErrorHint {
    static func text(for code: Int?) -> String {
        switch code.map(URLError.Code.init(rawValue:)) {
        case .cannotConnectToHost?, .cannotFindHost?, .dnsLookupFailed?:
            return "Check that the server is running and that the URL and port are right."
        case .timedOut?:
            return "The server did not answer in time. Try again, or raise the timeout in Settings."
        case .notConnectedToInternet?, .networkConnectionLost?:
            return "Check the network connection of this Mac."
        case .serverCertificateUntrusted?, .serverCertificateHasBadDate?, .serverCertificateHasUnknownRoot?, .serverCertificateNotYetValid?:
            return "The server's certificate is not trusted. If you trust this server, allow self-signed certificates in Settings."
        case .appTransportSecurityRequiresSecureConnection?:
            return "macOS blocked this plain HTTP connection. Use https:// if the server supports it."
        default:
            return "Check the URL and try again."
        }
    }
}
