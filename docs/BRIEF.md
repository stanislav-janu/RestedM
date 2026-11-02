# RestedM

A native SwiftUI HTTP client for one developer on macOS 27 (Apple Silicon) who builds and checks REST APIs and keeps requests as files.

## Replaces
RESTed 2.7, which no longer runs here. Its `.request` documents open and save unchanged.

## Main jobs
1. Compose a request (method, URL, headers, parameters or body, Basic auth) and send it with Command-R.
2. Read the response: status, timing, headers, pretty-printed and highlighted body; save the exchange as a transcript.
3. Switch between environments (dev, staging, prod) whose variables fill `{{name}}` across all documents.
4. Go back to an earlier sent request and its response from the history.
5. Move requests in and out as cURL: paste a `curl` command as a request, copy a request as `curl`.

## Data
- Request (`.request` XML plist, one per document window): method, URL, headers, parameters, encoding, custom body, string encoding, follow redirects, credentials, preserved RESTed keys.
- Exchange: sent request, status, response headers, body, timing, error.
- HistoryEntry: date, request snapshot, exchange summary, source document. Local, capped (decided by the agent).
- Environment: name, ordered variables (name, value, enabled); one active at a time, app-wide (decided by the agent).

## Shape
Document windows (one request per window, URL bar over a request editor and response pane split), macOS 27 or later. History and environments live outside the documents, in Application Support. Network only for the requests the user sends. No accounts.

## System hooks
Finder document type for `.request`, Request menu commands with shortcuts, pasteboard for cURL. No menu bar extra, no global shortcut.

## Reference
RESTed 2.7 (not installed on this Mac, so no reference screenshots; behaviour is described in README.md).

## Look
Native, built from Apple's controls, with the system accent color. It should read like a built-in Mac app: Xcode-like monospaced editors, standard split views and inspectors.

## Not in version one
- Editing OAuth and JSONP settings (kept in the file, not shown).
- Collections, workspaces, sync, sharing or teams.
- Scripts, tests and assertions on responses.
- GraphQL, WebSocket and gRPC.
