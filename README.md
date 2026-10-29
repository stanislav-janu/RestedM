# RestedM

Native SwiftUI HTTP client for macOS 27+ on Apple Silicon, a drop-in replacement for RESTed 2.7.

## Build

```bash
./scripts/build.sh
```

The script produces an ad-hoc signed arm64 bundle at `build/RestedM.app` and registers it with Launch Services. Copy it to `/Applications` to install.

## Tests

```bash
swift test
```

Optional checks against a local echo server and a folder of real `.request` documents:

```bash
RESTEDM_ECHO_URL=http://127.0.0.1:8765 RESTEDM_SAMPLES=/path/to/requests swift test
```

## Behaviour carried over from RESTed

- Documents are RESTed `.request` XML property lists. Keys RestedM does not edit (JSONP, OAuth tokens) are written back unchanged.
- `{{name}}` in the URL is replaced with the value of the enabled parameter `name`; that parameter is not sent again.
- Remaining parameters go to the query string for GET, HEAD, DELETE and TRACE, and to the body otherwise, form-encoded or as a JSON object in row order.
- A custom HTTP body replaces the parameters. GET and HEAD requests send parameters in the URL instead.
- A URL without a scheme gets `http://`.
- Basic authorization is answered on the server's challenge, or sent up front with “Send credentials before the authentication challenge”. The password is saved in the document only with “Remember password”.
- Settings use RESTed's keys: timeout, self-signed certificates, cookies, prettify sent JSON, pretty-print, syntax highlighting, line numbers and the default parameters/body layout.
- File ▸ Save Last Request & Response… writes a text transcript with optional request, response headers and response body.

## Layout

- `Sources/RestedCore`: document format, request building, HTTP client, JSON formatting. No UI.
- `Sources/RestedM`: SwiftUI app (document windows, editors, response view, settings).
- `scripts/`: bundle build script and icon renderer.
