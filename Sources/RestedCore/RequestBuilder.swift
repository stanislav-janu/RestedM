import Foundation

public struct SendOptions {
    public var timeout: TimeInterval
    public var useCookies: Bool
    public var prettifySentJSON: Bool

    public init(timeout: TimeInterval = 10, useCookies: Bool = false, prettifySentJSON: Bool = false) {
        self.timeout = timeout
        self.useCookies = useCookies
        self.prettifySentJSON = prettifySentJSON
    }
}

public struct BuiltRequest {
    public var urlRequest: URLRequest
    /// Headers in the order they were assembled, as shown in the request view.
    public var headers: [(name: String, value: String)]
    /// Credential for answering an authentication challenge (when not sent up front).
    public var credential: URLCredential?
}

public enum RequestBuilderError: Error, LocalizedError {
    case missingURL
    case invalidURL(String)

    public var errorDescription: String? {
        switch self {
        case .missingURL:
            return "Enter a URL to send the request to."
        case .invalidURL(let url):
            return "“\(url)” is not a valid URL."
        }
    }
}

/// Turns a document into a URLRequest following the rules of Rested 2.7:
/// `{{name}}` placeholders in the URL take the value of the matching parameter,
/// remaining parameters go to the query for GET/HEAD/DELETE/TRACE and to the body otherwise.
public struct RequestBuilder {
    static let queryMethods: Set<String> = ["GET", "HEAD", "DELETE", "TRACE"]
    static let placeholderPattern = try! NSRegularExpression(pattern: #"\{\{(\w+)\}\}"#)

    public let request: RestRequest
    public let options: SendOptions

    public init(request: RestRequest, options: SendOptions) {
        self.request = request
        self.options = options
    }

    var activeParameters: [KeyValueRow] {
        request.parameters.filter { $0.enabled && !$0.name.isEmpty }
    }

    var usesCustomBody: Bool {
        request.usesCustomBody && !request.customBodyIsIgnored
    }

    var appendsParametersToURL: Bool {
        !usesCustomBody && Self.queryMethods.contains(request.method)
    }

    var encoding: String.Encoding {
        String.Encoding(rawValue: request.stringEncoding)
    }

    public func build() throws -> BuiltRequest {
        let (template, usedNames) = expandPlaceholders(in: request.urlString.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !template.isEmpty else {
            throw RequestBuilderError.missingURL
        }
        let remaining = activeParameters.filter { !usedNames.contains($0.name) }

        var urlString = template
        if !urlString.contains("://") {
            urlString = "http://" + urlString
        }
        if appendsParametersToURL, !remaining.isEmpty {
            let separator = urlString.contains("?") ? "&" : "?"
            urlString += separator + Self.formEncoded(remaining)
        }
        guard let url = Self.makeURL(urlString) else {
            throw RequestBuilderError.invalidURL(urlString)
        }

        var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: options.timeout)
        urlRequest.httpMethod = request.method
        urlRequest.httpShouldHandleCookies = options.useCookies

        var headers: [(name: String, value: String)] = []
        func setHeader(_ name: String, _ value: String) {
            if let index = headers.firstIndex(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
                headers[index] = (name, value)
            } else {
                headers.append((name, value))
            }
        }

        if usesCustomBody {
            var body = request.body
            let isJSON = JSONPrettyPrinter.isJSON(body)
            if options.prettifySentJSON, isJSON, let pretty = JSONPrettyPrinter.format(body) {
                body = pretty
            }
            urlRequest.httpBody = data(body)
            setHeader("Content-Type", isJSON ? "application/json" : "text/plain")
        } else if !appendsParametersToURL, !remaining.isEmpty {
            switch request.parametersEncoding {
            case .form:
                urlRequest.httpBody = data(Self.formEncoded(remaining))
                setHeader("Content-Type", "application/x-www-form-urlencoded")
            case .json:
                urlRequest.httpBody = data(Self.jsonEncoded(remaining, pretty: options.prettifySentJSON))
                setHeader("Content-Type", "application/json")
            }
        }

        var userHeaderNames = Set<String>()
        for header in request.headers where header.enabled && !header.name.isEmpty {
            let key = header.name.lowercased()
            if userHeaderNames.contains(key) {
                headers.append((header.name, header.value))
            } else {
                userHeaderNames.insert(key)
                setHeader(header.name, header.value)
            }
        }

        var credential: URLCredential?
        if request.hasCredentials {
            if request.presentBeforeChallenge {
                let token = Data("\(request.username):\(request.password)".utf8).base64EncodedString()
                setHeader("Authorization", "Basic \(token)")
            } else {
                credential = URLCredential(user: request.username, password: request.password, persistence: .forSession)
            }
        }

        for header in headers {
            urlRequest.addValue(header.value, forHTTPHeaderField: header.name)
        }
        return BuiltRequest(urlRequest: urlRequest, headers: headers, credential: credential)
    }

    func expandPlaceholders(in template: String) -> (String, Set<String>) {
        let source = template as NSString
        let result = NSMutableString(string: template)
        var used = Set<String>()
        let matches = Self.placeholderPattern.matches(in: template, range: NSRange(location: 0, length: source.length))
        for match in matches.reversed() {
            let name = source.substring(with: match.range(at: 1))
            let values = activeParameters.filter { $0.name == name }.map(\.value)
            guard !values.isEmpty else {
                continue
            }
            used.insert(name)
            result.replaceCharacters(in: match.range, with: values.joined(separator: ","))
        }
        return (result as String, used)
    }

    func data(_ string: String) -> Data {
        string.data(using: encoding, allowLossyConversion: true) ?? Data(string.utf8)
    }

    static let formAllowed: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: "-._~")
        return set
    }()

    static func formEscape(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: formAllowed) ?? string
    }

    static func formEncoded(_ rows: [KeyValueRow]) -> String {
        rows.map { "\(formEscape($0.name))=\(formEscape($0.value))" }.joined(separator: "&")
    }

    static func jsonEncoded(_ rows: [KeyValueRow], pretty: Bool) -> String {
        let members = rows.map { "\(JSONPrettyPrinter.quote($0.name)):\(JSONPrettyPrinter.quote($0.value))" }
        let compact = "{" + members.joined(separator: ",") + "}"
        return pretty ? (JSONPrettyPrinter.format(compact) ?? compact) : compact
    }

    static func makeURL(_ string: String) -> URL? {
        if let url = URL(string: string), url.host != nil {
            return url
        }
        var allowed = CharacterSet.urlFragmentAllowed
        allowed.insert(charactersIn: "#%")
        guard let escaped = string.addingPercentEncoding(withAllowedCharacters: allowed),
              let url = URL(string: escaped), url.host != nil else {
            return nil
        }
        return url
    }
}
