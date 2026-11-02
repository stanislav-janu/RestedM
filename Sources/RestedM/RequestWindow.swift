import RestedCore
import SwiftUI

struct RequestWindow: View {
    @Binding var request: RestRequest

    @State private var exchange: HTTPExchange?
    @State private var sendTask: Task<Void, Never>?
    @State private var sendID: UUID?
    @State private var showsAuthorization = false
    @FocusState private var urlFocused: Bool

    private var isSending: Bool {
        sendTask != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            urlBar
            Divider()
            HSplitView {
                RequestEditor(request: $request, showsAuthorization: $showsAuthorization)
                    .frame(minWidth: Layout.editorMinWidth, idealWidth: Layout.editorIdealWidth, maxHeight: .infinity)
                ResponsePane(exchange: exchange, isSending: isSending)
                    .frame(minWidth: Layout.responseMinWidth, idealWidth: Layout.responseIdealWidth, maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(minWidth: Layout.windowMinWidth, minHeight: Layout.windowMinHeight)
        .sheet(isPresented: $showsAuthorization) {
            AuthorizationSheet(request: $request)
        }
        .focusedSceneValue(\.requestActions, RequestActions(
            send: toggleSend,
            focusURL: { urlFocused = true },
            exportLast: exportLast,
            canExport: exchange != nil,
            isSending: isSending
        ))
        .onAppear {
            if request.urlString.isEmpty {
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
            .frame(width: Layout.methodPickerWidth)

            TextField("http://localhost:3000/", text: $request.urlString)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .focused($urlFocused)
                .onSubmit(send)

            Button(action: toggleSend) {
                if isSending {
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

    private func toggleSend() {
        if let sendTask {
            sendTask.cancel()
            self.sendTask = nil
            sendID = nil
        } else {
            send()
        }
    }

    private func send() {
        guard sendTask == nil else {
            return
        }
        let snapshot = request
        let options = Preferences.sendOptions
        let built: BuiltRequest
        do {
            built = try RequestBuilder(request: snapshot, options: options).build()
        } catch {
            presentError(error)
            return
        }
        let id = UUID()
        sendID = id
        sendTask = Task {
            let result = await HTTPClient.send(
                built,
                request: snapshot,
                options: options,
                allowInvalidCertificates: Preferences.allowsInvalidCertificates
            )
            guard sendID == id else {
                return
            }
            if !Task.isCancelled {
                exchange = result
            }
            sendTask = nil
            sendID = nil
        }
    }

    private func presentError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "The request could not be sent."
        alert.informativeText = error.localizedDescription
        alert.runModal()
    }

    private func exportLast() {
        guard let exchange else {
            return
        }
        TranscriptExporter.run(exchange: exchange)
    }
}
