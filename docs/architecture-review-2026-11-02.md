# Architecture review, 2 November 2026 (end of M2)

Survey: 3,173 lines in two targets. The largest file is `RequestEditor.swift` (272 lines). No type is over 400 lines and no `private struct` is duplicated. `docs/FIXLOG.md` has one entry.

## One rule for which methods send parameters in the URL  [Strong, done]

Files: Sources/RestedCore/RequestBuilder.swift, Sources/RestedM/RequestEditor.swift
Signal: the same kind of bug would happen twice, because two copies of one rule can drift.
Problem: `RequestBuilder.queryMethods` decides where parameters go, and the editor's "GET sends the parameters in the URL." line kept its own list of the same four methods.
Proposal: `RestRequest.sendsParametersInURL`, read by both.
Benefits: locality, since a change to the rule is one line in RestedCore.
Proof of same behavior: all 22 unit tests pass, and the request-filled and request-body snapshots are unchanged.
Plan: one step (done).

## Sending behind a seam  [Worth exploring]

Files: Sources/RestedM/RequestSession.swift
Signal: a dependency cannot be replaced in a test.
Problem: `RequestSession` calls `HTTPClient.send` and reads `Preferences` directly. The stale-result guard (a stopped request must not show its late response) has no test. It was only checked by hand with Command-R.
Proposal: `RequestSession(send: @escaping (BuiltRequest, RestRequest) async -> HTTPExchange = HTTPClient.live)`. A self-test adapter returns a canned exchange after a delay.
Benefits: send, stop and the stale guard become self-test checks, and History (M4) can hook in at the same seam.
Plan: add the closure, then add self-test checks for send, stop and stale results.

## Commands out of the app file  [Worth exploring]

Files: Sources/RestedM/RestedMApp.swift (160 lines)
Signal: each new menu command (M3 environments, M4 history, M5 cURL) lands in the file that also holds the document type and app delegate.
Proposal: move `RequestActions`, the focused values and `RequestCommands` to `Commands.swift`, before M3.

## Considered, not recommended

- Splitting `RequestEditor.swift`: it is under 300 lines, and `ResolvedURLLine`, `AuthorizationSheet` and `Credentials` are only used there.
- A protocol for the agent-run registry in `Snapshot`: it has one conformer and test-only use.

## Top recommendation

Sending behind a seam, before M4, because History needs the same hook.
