# RestedM architecture

## Targets

- `RestedCore`: the `.request` file format (`RequestFile`), the request model (`RestRequest`), request building (`RequestBuilder`), sending (`HTTPClient`, `HTTPExchange`), JSON formatting and header parsing. Foundation only, no UI. Unit tests in `Tests/RestedCoreTests`.
- `RestedM`: the SwiftUI app. It depends on `RestedCore`.

## Layers in the app

- `RestedMApp.swift`: `DocumentGroup` with `RequestDocument`, the app delegate, and menu commands. Commands reach the key window through focused values (`requestActions`, `request`).
- `RequestWindow`: one window per document. It owns a `RequestSession` (`@Observable`, main actor) that holds view state: the last exchange, the running send, the response tab, the Authorization sheet, and a build error. The document holds only the `RestRequest`.
- Views: `RequestEditor` (headers, parameters, body), `ResponsePane`, `KeyValueEditor`, `BodyEditor` and `CodeTextView` (AppKit text views).
- `UI/`: design tokens (`Theme`, `Grid`, `Radius`, `Metrics`) and `WindowBehavior`. See `design/DESIGN-SYSTEM.md`.
- Agent runs: `Snapshot` (`RESTEDM_SNAPSHOT`) and `SelfTest` (`RESTEDM_SELFTEST`) open seed documents from `SeedData`, set view state through registered sessions, and never edit a document.

## Rules

- Rules about how a request is sent live in `RestedCore` and are read by the views (`RestRequest.sendsParametersInURL`, `RequestBuilder.resolvedURL`).
- Sheets edit a copy of document values and write back only a real change (`docs/FIXLOG.md`).
