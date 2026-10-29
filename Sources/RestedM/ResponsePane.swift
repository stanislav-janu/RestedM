import RestedCore
import SwiftUI

struct ResponsePane: View {
    let exchange: HTTPExchange?
    let isSending: Bool

    @AppStorage(Preferences.defaultResponseTab) private var defaultTab = ResponseTab.body.rawValue
    @AppStorage(Preferences.prettyPrint) private var prettyPrint = true
    @AppStorage(Preferences.highlightSyntax) private var highlightSyntax = true
    @AppStorage(Preferences.lineNumbers) private var lineNumbers = false
    @State private var tab: ResponseTab?

    private var selectedTab: Binding<ResponseTab> {
        Binding(
            get: { tab ?? ResponseTab(rawValue: defaultTab) ?? .body },
            set: { tab = $0 }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if let exchange {
                summary(exchange)
                Divider()
                Picker("View", selection: selectedTab) {
                    ForEach(ResponseTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                CodeTextView(
                    text: ResponseRenderer.render(exchange, tab: selectedTab.wrappedValue, pretty: prettyPrint, highlight: highlightSyntax),
                    showsLineNumbers: lineNumbers
                )
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
                    .padding(10)
            }
        }
    }

    private func summary(_ exchange: HTTPExchange) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(exchange.method)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 4))
                Text(exchange.url.absoluteString)
                    .font(.system(.callout, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }
            HStack(spacing: 12) {
                if let status = exchange.statusLine, let code = exchange.response?.statusCode {
                    Text(status)
                        .font(.callout.bold())
                        .foregroundStyle(statusColor(code))
                } else if let error = exchange.errorMessage {
                    Label(error, systemImage: "xmark.octagon.fill")
                        .font(.callout)
                        .foregroundStyle(.red)
                        .lineLimit(2)
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
        .padding(12)
    }

    private func statusColor(_ code: Int) -> Color {
        switch code {
        case 200..<300:
            return .green
        case 300..<400:
            return .blue
        case 400..<500:
            return .orange
        default:
            return .red
        }
    }

    private func formatted(_ interval: TimeInterval) -> String {
        if interval < 1 {
            return "\(Int((interval * 1000).rounded())) ms"
        }
        return String(format: "%.2f s", interval)
    }
}
