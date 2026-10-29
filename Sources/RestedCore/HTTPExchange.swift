import Foundation

/// One sent request with its response, as shown in the response pane and exported to a file.
public struct HTTPExchange {
    public let id = UUID()
    public var method: String
    public var url: URL
    public var requestHeaders: [(name: String, value: String)]
    public var requestBody: Data?
    public var requestEncoding: String.Encoding
    public var response: HTTPURLResponse?
    public var body: Data
    public var elapsed: TimeInterval
    public var errorMessage: String?

    public var statusLine: String? {
        guard let response else {
            return nil
        }
        let reason = Self.reasonPhrases[response.statusCode]
            ?? HTTPURLResponse.localizedString(forStatusCode: response.statusCode).capitalized
        return "\(response.statusCode) \(reason)"
    }

    static let reasonPhrases: [Int: String] = [
        100: "Continue", 101: "Switching Protocols",
        200: "OK", 201: "Created", 202: "Accepted", 203: "Non-Authoritative Information", 204: "No Content",
        205: "Reset Content", 206: "Partial Content",
        300: "Multiple Choices", 301: "Moved Permanently", 302: "Found", 303: "See Other", 304: "Not Modified",
        307: "Temporary Redirect", 308: "Permanent Redirect",
        400: "Bad Request", 401: "Unauthorized", 402: "Payment Required", 403: "Forbidden", 404: "Not Found",
        405: "Method Not Allowed", 406: "Not Acceptable", 408: "Request Timeout", 409: "Conflict", 410: "Gone",
        411: "Length Required", 412: "Precondition Failed", 413: "Content Too Large", 414: "URI Too Long",
        415: "Unsupported Media Type", 416: "Range Not Satisfiable", 418: "I'm a Teapot",
        422: "Unprocessable Content", 425: "Too Early", 426: "Upgrade Required", 428: "Precondition Required",
        429: "Too Many Requests", 431: "Request Header Fields Too Large", 451: "Unavailable For Legal Reasons",
        500: "Internal Server Error", 501: "Not Implemented", 502: "Bad Gateway", 503: "Service Unavailable",
        504: "Gateway Timeout", 505: "HTTP Version Not Supported",
    ]

    public var responseHeaders: [(name: String, value: String)] {
        guard let response else {
            return []
        }
        return response.allHeaderFields
            .map { (name: "\($0.key)", value: "\($0.value)") }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    public var contentType: String {
        response?.value(forHTTPHeaderField: "Content-Type")?.lowercased() ?? ""
    }

    public var requestBodyText: String? {
        guard let requestBody, !requestBody.isEmpty else {
            return nil
        }
        return String(data: requestBody, encoding: requestEncoding) ?? String(decoding: requestBody, as: UTF8.self)
    }

    /// The response body decoded with the charset the server declared, or nil for binary data.
    public var bodyText: String? {
        if body.isEmpty {
            return ""
        }
        if let name = response?.textEncodingName {
            let cfEncoding = CFStringConvertIANACharSetNameToEncoding(name as CFString)
            if cfEncoding != kCFStringEncodingInvalidId {
                let encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
                if let text = String(data: body, encoding: encoding) {
                    return text
                }
            }
        }
        if let text = String(data: body, encoding: .utf8) {
            return text
        }
        let type = contentType
        if type.hasPrefix("text/") || type.contains("json") || type.contains("xml") || type.contains("javascript") {
            return String(data: body, encoding: .isoLatin1)
        }
        return nil
    }

    /// Plain-text transcript used by “Save Last Request & Response…”.
    public func transcript(includeRequest: Bool, includeResponseHeaders: Bool, includeResponseBody: Bool) -> String {
        var sections: [String] = []
        if includeRequest {
            var lines = ["\(method) \(url.absoluteString)"]
            lines += requestHeaders.map { "\($0.name): \($0.value)" }
            if let text = requestBodyText {
                lines += ["", text]
            }
            sections.append(lines.joined(separator: "\n"))
        }
        if includeResponseHeaders {
            var lines = [statusLine.map { "HTTP \($0)" } ?? (errorMessage ?? "No response")]
            lines += responseHeaders.map { "\($0.name): \($0.value)" }
            sections.append(lines.joined(separator: "\n"))
        }
        if includeResponseBody {
            sections.append(bodyText ?? "<\(body.count) bytes of binary data>")
        }
        return sections.joined(separator: "\n\n") + "\n"
    }
}

/// Sends one request with Rested's redirect, certificate and authentication rules.
public final class HTTPClient: NSObject, URLSessionTaskDelegate {
    private let followRedirects: Bool
    private let allowInvalidCertificates: Bool
    private let credential: URLCredential?

    public init(followRedirects: Bool, allowInvalidCertificates: Bool, credential: URLCredential?) {
        self.followRedirects = followRedirects
        self.allowInvalidCertificates = allowInvalidCertificates
        self.credential = credential
    }

    public static func send(_ built: BuiltRequest, request: RestRequest, options: SendOptions, allowInvalidCertificates: Bool) async -> HTTPExchange {
        let client = HTTPClient(
            followRedirects: request.followRedirects,
            allowInvalidCertificates: allowInvalidCertificates,
            credential: built.credential
        )
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = options.timeout
        configuration.urlCache = nil
        configuration.httpAdditionalHeaders = ["User-Agent": "RestedM/1.0"]
        if options.useCookies {
            configuration.httpCookieStorage = .shared
            configuration.httpCookieAcceptPolicy = .always
            configuration.httpShouldSetCookies = true
        } else {
            configuration.httpCookieStorage = nil
            configuration.httpShouldSetCookies = false
        }
        let session = URLSession(configuration: configuration, delegate: client, delegateQueue: nil)
        defer {
            session.finishTasksAndInvalidate()
        }

        var exchange = HTTPExchange(
            method: request.method,
            url: built.urlRequest.url!,
            requestHeaders: built.headers,
            requestBody: built.urlRequest.httpBody,
            requestEncoding: String.Encoding(rawValue: request.stringEncoding),
            response: nil,
            body: Data(),
            elapsed: 0,
            errorMessage: nil
        )
        let start = Date()
        do {
            let (data, response) = try await session.data(for: built.urlRequest)
            exchange.response = response as? HTTPURLResponse
            exchange.body = data
        } catch {
            exchange.errorMessage = error.localizedDescription
        }
        exchange.elapsed = Date().timeIntervalSince(start)
        return exchange
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
        followRedirects ? request : nil
    }

    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        answer(challenge)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        answer(challenge)
    }

    private func answer(_ challenge: URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        switch challenge.protectionSpace.authenticationMethod {
        case NSURLAuthenticationMethodServerTrust:
            if allowInvalidCertificates, let trust = challenge.protectionSpace.serverTrust {
                return (.useCredential, URLCredential(trust: trust))
            }
            return (.performDefaultHandling, nil)
        case NSURLAuthenticationMethodHTTPBasic, NSURLAuthenticationMethodHTTPDigest, NSURLAuthenticationMethodNTLM:
            if let credential, challenge.previousFailureCount == 0 {
                return (.useCredential, credential)
            }
            return (.rejectProtectionSpace, nil)
        default:
            return (.performDefaultHandling, nil)
        }
    }
}
