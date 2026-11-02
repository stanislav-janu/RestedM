import RestedCore
import SwiftUI

struct RequestWindow: View {
    @Binding var request: RestRequest

    @State private var session = RequestSession()
    @FocusState private var urlFocused: Bool
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 0) {
            urlBar
            Divider()
            HSplitView {
                RequestEditor(request: $request, showsAuthorization: $session.showsAuthorization)
                    .frame(minWidth: Metrics.editorMinWidth, idealWidth: Metrics.editorIdealWidth, maxHeight: .infinity)
                ResponsePane(exchange: session.exchange, isSending: session.isSending, tab: $session.responseTab)
                    .frame(minWidth: Metrics.responseMinWidth, idealWidth: Metrics.responseIdealWidth, maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(minWidth: Metrics.windowMinWidth, minHeight: Metrics.windowMinHeight)
        .background(WindowReader { session.window = $0 })
        .sheet(isPresented: $session.showsAuthorization) {
            AuthorizationSheet(request: $request)
        }
        .focusedSceneValue(\.requestActions, RequestActions(
            send: { session.toggleSend(request) },
            focusURL: { urlFocused = true },
            exportLast: exportLast,
            canExport: session.exchange != nil,
            isSending: session.isSending
        ))
        .onAppear {
            if Snapshot.isActive || SelfTest.isActive {
                Snapshot.register(session, openSettings: openSettings)
            } else if request.urlString.isEmpty {
                urlFocused = true
            }
        }
    }

    private var urlBar: some View {
        HStack(spacing: Space.sm) {
            Picker("Method", selection: $request.method) {
                ForEach(methodChoices, id: \.self) { method in
                    Text(method).tag(method)
                }
            }
            .labelsHidden()
            .frame(width: Metrics.methodPickerWidth)

            TextField("http://localhost:3000/", text: $request.urlString)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .focused($urlFocused)
                .onSubmit { session.send(request) }

            Button {
                session.toggleSend(request)
            } label: {
                if session.isSending {
                    Label("Stop", systemImage: "stop.fill")
                } else {
                    Label("Send Request", systemImage: "paperplane.fill")
                }
            }
            .buttonStyle(.borderedProminent)
            .help("Send Request (⌘R)")
        }
        .padding(.horizontal, Space.pane)
        .padding(.vertical, Space.sm)
    }

    private var methodChoices: [String] {
        RestRequest.methods.contains(request.method) ? RestRequest.methods : RestRequest.methods + [request.method]
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
