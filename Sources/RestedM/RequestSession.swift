import AppKit
import Observation
import RestedCore

/// View state of one request window: the last exchange, the running send, and what is shown.
/// The document holds only the request; everything here is lost when the window closes.
@MainActor
@Observable
final class RequestSession {
    var exchange: HTTPExchange?
    /// The response tab picked in this window; nil follows the default from Settings.
    var responseTab: ResponseTab?
    var showsAuthorization = false
    /// Why the last Send Request could not build a request; shown in the response pane.
    var buildError: String?
    @ObservationIgnored weak var window: NSWindow?

    private var sendTask: Task<Void, Never>?
    private var sendID: UUID?

    var isSending: Bool {
        sendTask != nil
    }

    func toggleSend(_ request: RestRequest) {
        if isSending {
            stop()
        } else {
            send(request)
        }
    }

    func send(_ request: RestRequest) {
        guard sendTask == nil else {
            return
        }
        let options = Preferences.sendOptions
        let built: BuiltRequest
        do {
            built = try RequestBuilder(request: request, options: options).build()
        } catch {
            buildError = error.localizedDescription
            return
        }
        buildError = nil
        let id = UUID()
        sendID = id
        sendTask = Task {
            let result = await HTTPClient.send(
                built,
                request: request,
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

    func stop() {
        sendTask?.cancel()
        sendTask = nil
        sendID = nil
    }
}
