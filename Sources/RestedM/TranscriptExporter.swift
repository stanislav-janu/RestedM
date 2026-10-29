import AppKit
import RestedCore
import SwiftUI

/// “Save Last Request & Response…”: writes a plain-text transcript of the last exchange.
enum TranscriptExporter {
    final class Options: ObservableObject {
        @Published var includeRequest = true
        @Published var includeResponseHeaders = true
        @Published var includeResponseBody = true
    }

    struct OptionsView: View {
        @ObservedObject var options: Options

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Include Request Headers & Body", isOn: $options.includeRequest)
                Toggle("Include Response Headers", isOn: $options.includeResponseHeaders)
                Toggle("Include Response Body", isOn: $options.includeResponseBody)
            }
            .padding(12)
        }
    }

    @MainActor
    static func run(exchange: HTTPExchange) {
        let options = Options()
        let panel = NSSavePanel()
        panel.title = "Save Last Request & Response"
        panel.nameFieldStringValue = (exchange.url.lastPathComponent.isEmpty ? "response" : exchange.url.lastPathComponent) + ".txt"
        panel.allowedContentTypes = [.plainText]
        let accessory = NSHostingView(rootView: OptionsView(options: options))
        accessory.frame.size = accessory.fittingSize
        panel.accessoryView = accessory
        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }
        let text = exchange.transcript(
            includeRequest: options.includeRequest,
            includeResponseHeaders: options.includeResponseHeaders,
            includeResponseBody: options.includeResponseBody
        )
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            NSAlert(error: error).runModal()
        }
    }
}
