import Foundation

/// Reads and writes the `.request` XML property list used by Rested 2.x.
public enum RequestFile {
    public enum Error: Swift.Error, LocalizedError {
        case notADictionary

        public var errorDescription: String? {
            "The file is not a RESTed request document."
        }
    }

    private static let editedKeys: Set<String> = [
        "baseURL", "httpMethod", "headers", "parameters", "parametersType", "usingHTTPBody",
        "bodyString", "stringEncoding", "followRedirect", "username", "password",
        "shouldStorePassword", "presentBeforeChallenge", "paramBodyUIChoice",
    ]

    public static func decode(_ data: Data) throws -> RestRequest {
        let object = try PropertyListSerialization.propertyList(from: data, format: nil)
        guard let plist = object as? [String: Any] else {
            throw Error.notADictionary
        }

        var request = RestRequest()
        request.urlString = plist["baseURL"] as? String ?? ""
        request.method = (plist["httpMethod"] as? String).flatMap { $0.isEmpty ? nil : $0.uppercased() } ?? "GET"
        request.headers = rows(plist["headers"], nameKey: "header")
        request.parameters = rows(plist["parameters"], nameKey: "parameter")
        request.parametersEncoding = ParametersEncoding(rawValue: int(plist["parametersType"]) ?? 0) ?? .form
        request.usesCustomBody = bool(plist["usingHTTPBody"]) ?? false
        request.body = plist["bodyString"] as? String ?? ""
        request.stringEncoding = UInt(int(plist["stringEncoding"]) ?? Int(String.Encoding.utf8.rawValue))
        request.followRedirects = bool(plist["followRedirect"]) ?? true
        request.username = plist["username"] as? String ?? ""
        request.password = plist["password"] as? String ?? ""
        request.storePassword = bool(plist["shouldStorePassword"]) ?? !request.password.isEmpty
        request.presentBeforeChallenge = bool(plist["presentBeforeChallenge"]) ?? false
        request.paramBodyUIChoice = int(plist["paramBodyUIChoice"]) ?? 0
        request.preserved = PreservedFields(plist.filter { !editedKeys.contains($0.key) })
        return request
    }

    public static func encode(_ request: RestRequest) throws -> Data {
        var plist = request.preserved.dictionary
        plist["baseURL"] = request.urlString
        plist["httpMethod"] = request.method
        plist["headers"] = request.headers.map { ["header": $0.name, "value": $0.value, "inUse": $0.enabled] }
        plist["parameters"] = request.parameters.map { ["parameter": $0.name, "value": $0.value, "inUse": $0.enabled] }
        plist["parametersType"] = request.parametersEncoding.rawValue
        plist["usingHTTPBody"] = request.usesCustomBody
        plist["stringEncoding"] = Int(request.stringEncoding)
        plist["followRedirect"] = request.followRedirects
        plist["presentBeforeChallenge"] = request.presentBeforeChallenge
        plist["paramBodyUIChoice"] = request.paramBodyUIChoice
        plist["bodyString"] = request.body.isEmpty ? nil : request.body
        plist["username"] = request.username.isEmpty ? nil : request.username
        plist["shouldStorePassword"] = request.username.isEmpty ? nil : request.storePassword
        plist["password"] = request.storePassword && !request.password.isEmpty ? request.password : nil
        plist["jsonpScript"] = plist["jsonpScript"] ?? ""
        plist["handleJSONPCallbacks"] = plist["handleJSONPCallbacks"] ?? false
        return try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    }

    private static func rows(_ value: Any?, nameKey: String) -> [KeyValueRow] {
        guard let items = value as? [[String: Any]] else {
            return []
        }
        return items.map { item in
            KeyValueRow(
                enabled: bool(item["inUse"]) ?? true,
                name: item[nameKey] as? String ?? "",
                value: item["value"] as? String ?? ""
            )
        }
    }

    private static func bool(_ value: Any?) -> Bool? {
        if let bool = value as? Bool {
            return bool
        }
        return (value as? NSNumber)?.boolValue
    }

    private static func int(_ value: Any?) -> Int? {
        if let int = value as? Int {
            return int
        }
        return (value as? NSNumber)?.intValue
    }
}
