import RestedCore
import SwiftUI
import UniformTypeIdentifiers

struct RequestWindow: View {
    @Binding var request: RestRequest

    @State private var session = RequestSession()
    /// A new, empty request focuses its URL; a saved one opens with nothing focused.
    @State private var startsEmpty: Bool
    @FocusState private var urlFocused: Bool
    @Environment(\.openSettings) private var openSettings

    init(request: Binding<RestRequest>) {
        _request = request
        _startsEmpty = State(initialValue: request.wrappedValue.urlString.isEmpty)
    }

    var body: some View {
        HSplitView {
            RequestEditor(request: $request)
                .frame(minWidth: Metrics.editorMinWidth, idealWidth: Metrics.editorIdealWidth, maxHeight: .infinity)
            ResponsePane(exchange: session.exchange, buildError: session.buildError, isSending: session.isSending, tab: $session.responseTab)
                .frame(minWidth: Metrics.responseMinWidth, idealWidth: Metrics.responseIdealWidth, maxHeight: .infinity)
        }
        .frame(minWidth: Metrics.windowMinWidth, minHeight: Metrics.windowMinHeight)
        .toolbar {
            ToolbarItem(placement: .principal) {
                addressBar
            }
            ToolbarItemGroup(placement: .primaryAction) {
                authorizationButton
                Menu {
                    RequestOptionsMenuContent(request: $request)
                } label: {
                    Label("Request Options", systemImage: "slider.horizontal.3")
                }
                .help("Choose the text encoding and whether to follow redirects")
            }
            ToolbarSpacer(.fixed, placement: .primaryAction)
            ToolbarItem(placement: .primaryAction) {
                sendButton
            }
        }
        .background(WindowReader { session.window = $0 })
        .noInitialFocus(!startsEmpty || Snapshot.isActive)
        .sheet(isPresented: $session.showsAuthorization) {
            AuthorizationSheet(request: $request)
        }
        .focusedSceneValue(\.request, $request)
        .focusedSceneValue(\.requestActions, RequestActions(
            send: { session.toggleSend(request) },
            showAuthorization: { session.showsAuthorization = true },
            copyResponseBody: copyResponseBody,
            showResponseTab: { session.responseTab = $0 },
            hasResponse: session.exchange != nil,
            focusURL: { urlFocused = true },
            exportLast: exportLast,
            canExport: session.exchange != nil,
            isSending: session.isSending
        ))
        .onAppear {
            if Snapshot.isActive || SelfTest.isActive {
                Snapshot.register(session, openSettings: openSettings)
            } else if startsEmpty {
                urlFocused = true
            }
        }
    }

    /// Method and URL, one toolbar group that takes the free width.
    private var addressBar: some View {
        HStack(spacing: Space.sm) {
            Menu {
                Picker("Method", selection: $request.method) {
                    ForEach(methodChoices, id: \.self) { method in
                        Text(method).tag(method)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } label: {
                MethodBadge(method: request.method)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .fixedSize()
            .help("Choose the HTTP method")
            .accessibilityLabel("Method, \(request.method)")

            TextField("URL", text: $request.urlString, prompt: Text("Enter a URL"))
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .focused($urlFocused)
                .onSubmit { session.send(request) }
                .frame(minWidth: Metrics.urlFieldMinWidth, idealWidth: Metrics.urlFieldIdealWidth, maxWidth: .infinity)
        }
    }

    private var authorizationButton: some View {
        Button {
            session.showsAuthorization = true
        } label: {
            Label("Authorization", systemImage: request.hasCredentials ? "lock.fill" : "lock.open")
        }
        .help(request.hasCredentials
            ? "Basic authorization as \(request.username) (⌥⌘A)"
            : "Set a username and password for Basic authorization (⌥⌘A)")
    }

    private var sendButton: some View {
        Button {
            session.toggleSend(request)
        } label: {
            if session.isSending {
                Label("Stop Request", systemImage: "stop.fill")
            } else {
                Label("Send Request", systemImage: "paperplane.fill")
            }
        }
        .labelStyle(.titleAndIcon)
        .buttonStyle(.borderedProminent)
        .help(session.isSending ? "Stop the request (⌘R)" : "Send the request (⌘R)")
    }

    private var methodChoices: [String] {
        RestRequest.methods.contains(request.method) ? RestRequest.methods : RestRequest.methods + [request.method]
    }

    private func copyResponseBody() {
        guard let exchange = session.exchange else {
            return
        }
        NSPasteboard.general.clearContents()
        if let text = exchange.bodyText {
            NSPasteboard.general.setString(text, forType: .string)
        } else {
            let mime = exchange.contentType.split(separator: ";").first.map(String.init) ?? ""
            let type = UTType(mimeType: mime.trimmingCharacters(in: .whitespaces)) ?? .data
            NSPasteboard.general.setData(exchange.body, forType: NSPasteboard.PasteboardType(type.identifier))
        }
    }

    private func exportLast() {
        guard let exchange = session.exchange else {
            return
        }
        TranscriptExporter.run(exchange: exchange)
    }
}

/// Hands the hosting NSWindow to SwiftUI state once the view is in a window.
struct WindowReader: NSViewRepresentable {
    let onWindow: (NSWindow) -> Void

    func makeNSView(context: Context) -> ReaderView {
        ReaderView(onWindow: onWindow)
    }

    func updateNSView(_ view: ReaderView, context: Context) {}

    final class ReaderView: NSView {
        let onWindow: (NSWindow) -> Void

        init(onWindow: @escaping (NSWindow) -> Void) {
            self.onWindow = onWindow
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            nil
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let window {
                onWindow(window)
            }
        }
    }
}
