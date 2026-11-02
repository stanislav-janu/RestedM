# RestedM design

Design plan and review notes for the `mac-design` rules. Tokens live in `design/DESIGN-SYSTEM.md`.

## Design plan

### Archetype
Single-window document: one `.request` per window, from `DocumentGroup`. Two utility windows (`Window` scenes): Environments and History. A `Settings` scene. The entry points are Finder (double-click a `.request`), File ▸ New (Command-N) and the pasteboard (cURL).

### Information architecture
- Request window, one navigation level, so the content takes the full width:
  - Toolbar: method, URL, active environment, Send.
  - Leading column: request editor with Headers, Parameters and HTTP Body.
  - Trailing column: response pane with summary, then Body, Headers and Request tabs.
- Environments window: sidebar of environments, variable rows in the detail.
- History window: one list grouped by day, search in the trailing toolbar.

### Command map

| Action | Menu | Shortcut |
| --- | --- | --- |
| New request | File ▸ New Request | Command-N |
| New request from cURL | File ▸ New Request from cURL… | Shift-Command-N |
| Save last request and response | File ▸ Save Last Request & Response… | Option-Command-S |
| Send or stop | Request ▸ Send Request / Stop Request | Command-R |
| Focus URL | Request ▸ Select URL Field | Command-L |
| Edit authorization | Request ▸ Authorization… | Option-Command-A |
| Copy as cURL | Request ▸ Copy as cURL | Option-Shift-Command-C |
| Copy response body | Edit ▸ Copy Response Body | Shift-Command-C |
| Response tabs | View ▸ Response Body / Headers / Request | Option-Command-1, 2, 3 |
| Environments window | Window ▸ Environments | Shift-Command-E |
| History window | Window ▸ History | Shift-Command-H |
| Find in response | Edit ▸ Find | Command-F |
| Settings | RestedM ▸ Settings… | Command-comma |

### Empty states
- Response pane before the first send: "No Response Yet", "Press ⌘R to send the request." (exists).
- Headers and parameters with no rows: one quiet line and the Add button (exists).
- Environments with none: `ContentUnavailableView` "No Environments" with an Add Environment button.
- History with no sends: "No Requests Sent", "Requests you send appear here."
- History search with no match: `ContentUnavailableView.search(text:)`.

### Feeling
Quick and confident: the request goes out the moment you press Command-R, the answer is readable at a glance, nothing in the window competes with the response.

## Review, 2 November 2026

Snapshots of the current window: request filled, response body, light appearance. Dark appearance is reviewed through S-009, which renders every page in both appearances inside the app.

| # | Finding | Rule | Story |
| --- | --- | --- | --- |
| 1 | Method, URL and Send sit in a custom bar under the title bar instead of the window toolbar. | 2, 16 | fixed: S-017 |
| 2 | Authorization, Encoding and Follow Redirects sit on the bottom edge of the window. | 64 | fixed: S-018 |
| 3 | The method picker shows a focus ring when a saved document opens (seen on a fresh launch). | 51 | fixed in snapshots; focus checks pending, S-017 |
| 4 | Headers take half the editor height for two rows, leaving a large empty band. | 27, review set | fixed: S-019 |
| 5 | The disabled body editor shows at full size while "Use Custom HTTP Body" is off. | 27 | fixed: S-019 |
| 6 | The method badge in the response summary is fixed white text on the accent fill. | 41, 50 | fixed: `Palette.onAccent` |
| 7 | JSON string green on the white response background is below 4.5:1 (2.1:1). | 50 | fixed: `CodeColors` |
| 8 | Header and parameter rows have no context menu. | 33, 68 | fixed: S-014 |
| 9 | Response tabs have no menu commands or shortcuts. | 17, 18 | fixed: S-013 |
| 10 | Errors from building a request use a modal alert. | 25, 79 | fixed: S-010 |
| 11 | A network error shows its message twice: in the summary and as the body. | 47 | fixed: S-010 |
| 12 | The third parameter row is clipped behind the Add button. | review set | fixed: S-019 |
| 13 | Opening the Authorization sheet marks the document as edited without a change. | 25 | fixed: S-018 |
| 14 | The Authorization sheet focuses and selects the username, and truncates the "Remember password" label. | 51, 52 | fixed: S-018 |
| 15 | Settings opens with a focus ring on the first switch. | 51 | fixed: S-019 |
| 16 | The empty URL field's placeholder renders in the link color. | 28 | fixed: S-017 |

Holds already: one prominent action (Send), title names the document, status color paired with the status text, system scroll bars, find bar in the response, monospaced URL and code, Settings on Command-comma.
