import Foundation
import Testing
@testable import RestedCore

// Opt-in checks against a local echo server and real Rested documents:
// RESTEDM_ECHO_URL=http://127.0.0.1:8765 RESTEDM_SAMPLES=/path/to/folder swift test
private let echoURL = ProcessInfo.processInfo.environment["RESTEDM_ECHO_URL"]
private let samplesPath = ProcessInfo.processInfo.environment["RESTEDM_SAMPLES"]

private func send(_ request: RestRequest) async throws -> (HTTPExchange, [String: Any]) {
    let options = SendOptions()
    let built = try RequestBuilder(request: request, options: options).build()
    let exchange = await HTTPClient.send(built, request: request, options: options, allowInvalidCertificates: false)
    let json = (try? JSONSerialization.jsonObject(with: exchange.body)) as? [String: Any] ?? [:]
    return (exchange, json)
}

private func echoRequest(_ method: String, _ path: String) -> RestRequest {
    var request = RestRequest()
    request.method = method
    request.urlString = echoURL! + path
    return request
}

@Suite(.enabled(if: echoURL != nil))
struct EchoServerTests {
    @Test func getWithQueryAndHeader() async throws {
        var request = echoRequest("GET", "/items/{{id}}")
        request.parameters = [KeyValueRow(name: "id", value: "7"), KeyValueRow(name: "q", value: "a b")]
        request.headers = [KeyValueRow(name: "X-Test", value: "yes")]
        let (exchange, json) = try await send(request)
        #expect(exchange.response?.statusCode == 200)
        #expect(json["path"] as? String == "/items/7")
        #expect(json["query"] as? String == "q=a%20b")
        #expect((json["headers"] as? [String: String])?["X-Test"] == "yes")
    }

    @Test func postJSONParameters() async throws {
        var request = echoRequest("POST", "/echo")
        request.parametersEncoding = .json
        request.parameters = [KeyValueRow(name: "b", value: "2"), KeyValueRow(name: "a", value: "1")]
        let (_, json) = try await send(request)
        #expect(json["body"] as? String == #"{"b":"2","a":"1"}"#)
        #expect((json["headers"] as? [String: String])?["Content-Type"] == "application/json")
    }

    @Test func customBodyOnPatch() async throws {
        var request = echoRequest("PATCH", "/echo")
        request.usesCustomBody = true
        request.body = "plain text"
        let (_, json) = try await send(request)
        #expect(json["method"] as? String == "PATCH")
        #expect(json["body"] as? String == "plain text")
    }

    @Test func redirects() async throws {
        var request = echoRequest("GET", "/redirect")
        let (followed, json) = try await send(request)
        #expect(followed.response?.statusCode == 200)
        #expect(json["query"] as? String == "redirected=1")

        request.followRedirects = false
        let (stopped, _) = try await send(request)
        #expect(stopped.response?.statusCode == 302)
    }

    @Test func crossOriginRedirectDropsAuthorization() async throws {
        var request = echoRequest("GET", "/redirect-away")
        request.headers = [KeyValueRow(name: "Authorization", value: "Bearer secret"), KeyValueRow(name: "X-Test", value: "yes")]
        let (exchange, json) = try await send(request)
        #expect(exchange.response?.statusCode == 200)
        #expect(json["query"] as? String == "away=1")
        let headers = json["headers"] as? [String: String]
        #expect(headers?["Authorization"] == nil)
        #expect(headers?["X-Test"] == "yes")
    }

    @Test func basicAuthChallengeAndPreemptive() async throws {
        var request = echoRequest("GET", "/auth")
        let (anonymous, _) = try await send(request)
        #expect(anonymous.response?.statusCode == 401)

        request.username = "user"
        request.password = "pass"
        let (challenged, _) = try await send(request)
        #expect(challenged.response?.statusCode == 200)

        request.presentBeforeChallenge = true
        let (preemptive, json) = try await send(request)
        #expect(preemptive.response?.statusCode == 200)
        #expect((json["headers"] as? [String: String])?["Authorization"] == "Basic dXNlcjpwYXNz")
    }
}

@Suite(.enabled(if: samplesPath != nil))
struct SampleDocumentTests {
    @Test func realDocumentsRoundTrip() throws {
        let folder = URL(fileURLWithPath: samplesPath!)
        let files = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "request" }
        #expect(!files.isEmpty)
        for file in files {
            let original = try PropertyListSerialization.propertyList(from: Data(contentsOf: file), format: nil) as! [String: Any]
            let request = try RequestFile.decode(Data(contentsOf: file))
            let saved = try PropertyListSerialization.propertyList(from: RequestFile.encode(request), format: nil) as! [String: Any]
            #expect(NSDictionary(dictionary: saved).isEqual(to: original), "\(file.lastPathComponent) changed on save")
        }
    }
}
