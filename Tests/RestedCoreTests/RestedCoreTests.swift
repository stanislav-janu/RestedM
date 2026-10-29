import Foundation
import Testing
@testable import RestedCore

private func request(_ method: String, _ url: String, parameters: [(String, String)] = []) -> RestRequest {
    var request = RestRequest()
    request.method = method
    request.urlString = url
    request.parameters = parameters.map { KeyValueRow(name: $0.0, value: $0.1) }
    return request
}

private func body(_ built: BuiltRequest) -> String {
    String(decoding: built.urlRequest.httpBody ?? Data(), as: UTF8.self)
}

@Test func getAppendsParametersToQuery() throws {
    let built = try RequestBuilder(request: request("GET", "example.com/search?x=1", parameters: [("q", "a b&c")]), options: SendOptions()).build()
    #expect(built.urlRequest.url?.absoluteString == "http://example.com/search?x=1&q=a%20b%26c")
    #expect(built.urlRequest.httpBody == nil)
}

@Test func placeholdersConsumeParameters() throws {
    let built = try RequestBuilder(request: request("GET", "https://api.test/users/{{id}}/posts", parameters: [("id", "42"), ("page", "2")]), options: SendOptions()).build()
    #expect(built.urlRequest.url?.absoluteString == "https://api.test/users/42/posts?page=2")
}

@Test func postSendsFormBody() throws {
    let built = try RequestBuilder(request: request("POST", "https://api.test/form", parameters: [("name", "Jan Novák"), ("x", "1")]), options: SendOptions()).build()
    #expect(body(built) == "name=Jan%20Nov%C3%A1k&x=1")
    #expect(built.urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
}

@Test func postSendsOrderedJSONParameters() throws {
    var req = request("PUT", "https://api.test/json", parameters: [("zeta", "1"), ("alpha", "\"quoted\"")])
    req.parametersEncoding = .json
    let built = try RequestBuilder(request: req, options: SendOptions()).build()
    #expect(body(built) == #"{"zeta":"1","alpha":"\"quoted\""}"#)
    #expect(built.urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
}

@Test func customBodyAndUserHeadersOverrideDefaults() throws {
    var req = request("POST", "https://api.test/raw")
    req.usesCustomBody = true
    req.body = #"{"b":1,"a":[]}"#
    req.headers = [
        KeyValueRow(name: "content-type", value: "application/vnd.api+json"),
        KeyValueRow(enabled: false, name: "X-Off", value: "1"),
    ]
    let built = try RequestBuilder(request: req, options: SendOptions(prettifySentJSON: true)).build()
    #expect(body(built) == "{\n  \"b\": 1,\n  \"a\": []\n}")
    #expect(built.urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/vnd.api+json")
    #expect(built.urlRequest.value(forHTTPHeaderField: "X-Off") == nil)
}

@Test func basicAuthentication() throws {
    var req = request("GET", "https://api.test/")
    req.username = "user"
    req.password = "pass"
    let challenged = try RequestBuilder(request: req, options: SendOptions()).build()
    #expect(challenged.urlRequest.value(forHTTPHeaderField: "Authorization") == nil)
    #expect(challenged.credential?.user == "user")

    req.presentBeforeChallenge = true
    let preemptive = try RequestBuilder(request: req, options: SendOptions()).build()
    #expect(preemptive.urlRequest.value(forHTTPHeaderField: "Authorization") == "Basic dXNlcjpwYXNz")
}

@Test func prettyPrinterKeepsKeyOrderAndStrings() {
    let source = #"{"z":{"y":[1,2,{}]},"a":"x, {y}: \"q\""}"#
    let expected = """
    {
      "z": {
        "y": [
          1,
          2,
          {}
        ]
      },
      "a": "x, {y}: \\"q\\""
    }
    """
    #expect(JSONPrettyPrinter.format(source) == expected)
    #expect(JSONPrettyPrinter.format("not json") == nil)
}

@Test func requestFileRoundTripKeepsUnknownKeys() throws {
    let plist: [String: Any] = [
        "baseURL": "https://api.test/x",
        "httpMethod": "POST",
        "headers": [["header": "Accept", "value": "application/json", "inUse": true]],
        "parameters": [["parameter": "a", "value": "1", "inUse": false]],
        "parametersType": 1,
        "usingHTTPBody": false,
        "stringEncoding": 4,
        "followRedirect": false,
        "presentBeforeChallenge": false,
        "paramBodyUIChoice": 0,
        "jsonpScript": "callback()",
        "handleJSONPCallbacks": true,
        "futureKey": ["nested": 1],
    ]
    let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    let decoded = try RequestFile.decode(data)
    #expect(decoded.method == "POST")
    #expect(decoded.headers.first?.name == "Accept")
    #expect(decoded.parameters.first?.enabled == false)
    #expect(decoded.parametersEncoding == .json)
    #expect(decoded.followRedirects == false)

    let reencoded = try PropertyListSerialization.propertyList(from: RequestFile.encode(decoded), format: nil) as! [String: Any]
    #expect(NSDictionary(dictionary: reencoded).isEqual(to: plist))
}

@Test func transcriptHonoursSections() throws {
    let url = URL(string: "https://api.test/items")!
    let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "text/plain"])
    let exchange = HTTPExchange(
        method: "POST",
        url: url,
        requestHeaders: [("Accept", "*/*")],
        requestBody: Data("a=1".utf8),
        requestEncoding: .utf8,
        response: response,
        body: Data("missing".utf8),
        elapsed: 0.1,
        errorMessage: nil
    )
    #expect(exchange.transcript(includeRequest: true, includeResponseHeaders: true, includeResponseBody: true)
        == "POST https://api.test/items\nAccept: */*\n\na=1\n\nHTTP 404 Not Found\nContent-Type: text/plain\n\nmissing\n")
    #expect(exchange.transcript(includeRequest: false, includeResponseHeaders: false, includeResponseBody: true) == "missing\n")
}
