import Foundation
import RestedCore

/// Sample request and canned responses for snapshot and self-test runs. No network.
enum SeedData {
    static var request: RestRequest {
        var request = RestRequest()
        request.method = "GET"
        request.urlString = "https://api.example.com/users/{{id}}"
        request.headers = [
            KeyValueRow(name: "Accept", value: "application/json"),
            KeyValueRow(name: "Accept-Language", value: "cs-CZ"),
            KeyValueRow(enabled: false, name: "X-Request-ID", value: "restedm-snapshot"),
        ]
        request.parameters = [
            KeyValueRow(name: "id", value: "42"),
            KeyValueRow(name: "include", value: "teams,roles"),
            KeyValueRow(enabled: false, name: "fields", value: "name,email"),
        ]
        request.username = "demo"
        return request
    }

    /// A POST with a custom JSON body that has one mistake, for the body editor page.
    static var bodyRequest: RestRequest {
        var request = RestRequest()
        request.method = "POST"
        request.urlString = "https://api.example.com/users"
        request.headers = [KeyValueRow(name: "Content-Type", value: "application/json")]
        request.usesCustomBody = true
        request.body = """
        {
          "name": "Jana Nováková",
          "email": "jana@example.com",
          "active": tru,
          "teams": [7, 12],
          "manager": null
        }
        """
        return request
    }

    /// Writes the sample request to a temporary `.request` file and returns its URL.
    static func writeRequestFile() throws -> URL {
        try write(request, named: "Users API.request")
    }

    static func writeBodyRequestFile() throws -> URL {
        try write(bodyRequest, named: "Create User.request")
    }

    private static func write(_ request: RestRequest, named name: String) throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("RestedM-seed", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent(name)
        try RequestFile.encode(request).write(to: url)
        return url
    }

    static var okExchange: HTTPExchange {
        exchange(status: 200, elapsed: 0.184, contentType: "application/json; charset=utf-8", body: """
        {"id":42,"name":"Jana Nováková","email":"jana@example.com","active":true,"manager":null,\
        "teams":[{"id":7,"name":"Platform","role":"owner"},{"id":12,"name":"Mobile","role":"member"}],\
        "roles":["admin","editor"],"quota":{"used":1.5,"limit":10},"created":"2024-03-18T09:41:00Z"}
        """)
    }

    static var notFoundExchange: HTTPExchange {
        exchange(status: 404, elapsed: 0.092, contentType: "application/problem+json", body: """
        {"type":"https://api.example.com/errors/not-found","title":"User not found","status":404,"detail":"No user has the id 42."}
        """)
    }

    static var errorExchange: HTTPExchange {
        var exchange = exchange(status: nil, elapsed: 0.012, contentType: nil, body: "")
        exchange.errorMessage = "Could not connect to the server."
        exchange.errorCode = URLError.cannotConnectToHost.rawValue
        return exchange
    }

    private static func exchange(status: Int?, elapsed: TimeInterval, contentType: String?, body: String) -> HTTPExchange {
        let built = try? RequestBuilder(request: request, options: SendOptions()).build()
        let url = built?.urlRequest.url ?? URL(string: "https://api.example.com/users/42")!
        var headers = [
            "Date": "Mon, 02 Nov 2026 09:41:00 GMT",
            "Server": "nginx",
            "Cache-Control": "no-store",
            "Content-Length": "\(body.utf8.count)",
        ]
        if let contentType {
            headers["Content-Type"] = contentType
        }
        let response = status.flatMap { HTTPURLResponse(url: url, statusCode: $0, httpVersion: "HTTP/1.1", headerFields: headers) }
        return HTTPExchange(
            method: request.method,
            url: url,
            requestHeaders: (built?.headers ?? []) + [("User-Agent", "RestedM/1.0")],
            requestBody: built?.urlRequest.httpBody,
            requestEncoding: .utf8,
            response: response,
            body: Data(body.utf8),
            elapsed: elapsed,
            errorMessage: nil
        )
    }
}
