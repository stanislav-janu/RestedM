import Foundation

public struct KeyValueRow: Identifiable, Hashable {
    public var id = UUID()
    public var enabled: Bool
    public var name: String
    public var value: String

    public init(enabled: Bool = true, name: String = "", value: String = "") {
        self.enabled = enabled
        self.name = name
        self.value = value
    }
}

public enum ParametersEncoding: Int, CaseIterable {
    case form = 0
    case json = 1
}

/// Keys of the original Rested document that RestedM does not edit
/// (JSONP, OAuth, unknown future keys). They are written back untouched.
public struct PreservedFields: Equatable {
    public var dictionary: [String: Any]

    public init(_ dictionary: [String: Any] = [:]) {
        self.dictionary = dictionary
    }

    public static func == (lhs: PreservedFields, rhs: PreservedFields) -> Bool {
        NSDictionary(dictionary: lhs.dictionary).isEqual(to: rhs.dictionary)
    }
}

public struct RestRequest: Equatable {
    public static let methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS", "TRACE"]

    public var urlString = ""
    public var method = "GET"
    public var headers: [KeyValueRow] = []
    public var parameters: [KeyValueRow] = []
    public var parametersEncoding: ParametersEncoding = .form
    public var usesCustomBody = false
    public var body = ""
    public var stringEncoding: UInt = String.Encoding.utf8.rawValue
    public var followRedirects = true
    public var username = ""
    public var password = ""
    public var storePassword = false
    public var presentBeforeChallenge = false
    public var paramBodyUIChoice = 0
    public var preserved = PreservedFields()

    public init() {}

    /// Rested refuses a custom body for these methods and sends parameters in the query instead.
    public var customBodyIsIgnored: Bool {
        ["GET", "HEAD"].contains(method)
    }

    public var hasCredentials: Bool {
        !username.isEmpty
    }
}
