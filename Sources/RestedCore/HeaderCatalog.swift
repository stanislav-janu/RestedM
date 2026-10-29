/// Common request header names and typical values offered in the header editor.
public enum HeaderCatalog {
    public static let values: [String: [String]] = [
        "Accept": [
            "application/json", "application/xml", "application/xhtml+xml", "application/atom+xml",
            "application/x-www-form-urlencoded", "text/css", "text/html", "text/plain", "*/*",
        ],
        "Accept-Charset": ["utf-8", "iso-8859-1"],
        "Accept-Encoding": ["gzip", "deflate", "br", "identity"],
        "Accept-Language": ["cs", "de", "en-GB", "en-US", "es", "fr", "pl", "sk"],
        "Authorization": ["Bearer "],
        "Cache-Control": ["no-cache", "no-store", "max-age=0"],
        "Connection": ["close", "keep-alive"],
        "Content-Length": [],
        "Content-MD5": [],
        "Content-Type": [
            "application/json", "application/x-www-form-urlencoded", "application/xml",
            "multipart/form-data", "text/plain",
        ],
        "Cookie": [],
        "Date": [],
        "Expect": ["100-continue"],
        "From": [],
        "Host": [],
        "If-Match": [],
        "If-Modified-Since": [],
        "If-None-Match": [],
        "If-Range": [],
        "If-Unmodified-Since": [],
        "Max-Forwards": [],
        "Origin": [],
        "Pragma": ["no-cache"],
        "Proxy-Authorization": [],
        "Range": ["bytes=0-1023"],
        "Referer": [],
        "TE": ["trailers", "deflate"],
        "Upgrade": [],
        "User-Agent": ["RestedM"],
        "Via": [],
        "Warning": [],
        "X-API-Key": [],
        "X-HTTP-Method-Override": ["DELETE", "PATCH", "PUT"],
        "X-Requested-With": ["XMLHttpRequest"],
    ]

    public static let names: [String] = values.keys.sorted()

    public static func suggestions(for name: String) -> [String] {
        values.first { $0.key.caseInsensitiveCompare(name) == .orderedSame }?.value ?? []
    }
}
