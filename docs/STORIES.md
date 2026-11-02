# RestedM stories

Built from `docs/BRIEF.md`. RESTed 2.7 is not installed, so `Screens:` names the snapshot pages that will show each story (`build/snapshots/<page>-light.png` and `-dark.png`, written by `scripts/snap.sh`), not reference screenshots.

Snapshot pages: `request-empty`, `request-filled`, `response-body`, `response-headers`, `response-sent`, `response-404`, `response-error`, `authorization-sheet`, `settings`, `environments`, `history`, `curl-import`.

## M1 Core loop (built before the backlog existed)

### S-001 Open and save a RESTed document
As the user, I open a `.request` file from Finder and save it back without losing keys RestedM does not edit.
Screens: request-filled
Acceptance:
- [unit] Decoding and encoding a sample `.request` keeps every key, including JSONP and OAuth.
- [manual] Double-clicking a `.request` file in Finder opens it in RestedM.
Status: done

### S-002 Compose a request
As the user, I pick a method, type a URL, and fill headers and parameters in rows with enable checkboxes.
Screens: request-empty, request-filled
Acceptance:
- [snap] URL bar with method picker, URL field and Send Request button sits above the editor and response split.
- [snap] Header names offer suggestions from the header catalog.
- [unit] `{{name}}` in the URL takes the enabled parameter's value and the parameter is not sent again.
Status: done

### S-003 Send a request with Command-R
As the user, I press Command-R and the response replaces the empty state; pressing it again while sending stops the request.
Screens: request-empty, response-body
Acceptance:
- [snap] Before the first send the response pane shows "No Response Yet".
- [self] Request ▸ Send Request turns into Stop Request while a request runs.
- [unit] Parameters go to the query for GET, HEAD, DELETE and TRACE, to the body otherwise.
Status: done

### S-004 Read the response
As the user, I see status, response time and size, and switch between body, headers and the sent request.
Screens: response-body, response-headers, response-sent
Acceptance:
- [snap] Status is colored by class (2xx green, 3xx blue, 4xx orange, 5xx red).
- [snap] JSON bodies are pretty-printed and highlighted when the settings say so.
- [manual] Command-F opens the find bar in the response body.
Status: done

### S-005 Send a custom body
As the user, I turn on "Use Custom HTTP Body" and type a raw body that replaces the parameters.
Screens: request-filled
Acceptance:
- [snap] For GET and HEAD a warning says the parameters go to the URL instead.
- [unit] A custom body replaces form or JSON parameters for POST.
Status: done

### S-006 Use Basic authorization
As the user, I set a username and password in the Authorization sheet, optionally sent before the challenge.
Screens: authorization-sheet
Acceptance:
- [snap] The options bar button reads "Authorization: <user>" with a closed lock once a username is set.
- [unit] The password is written to the document only with "Remember password".
Status: done

### S-007 Save the last exchange as a transcript
As the user, I choose File ▸ Save Last Request & Response… and get a text file.
Screens: response-body
Acceptance:
- [manual] Option-Command-S writes the request, response headers and body as chosen in the save panel.
Status: done

### S-008 Change settings
As the user, I set timeout, certificates, cookies and response display in Settings.
Screens: settings
Acceptance:
- [unit] Settings use RESTed's defaults keys.
- [snap] Settings show network and display options in grouped form.
Status: done

## M2 Window polish

### S-009 Snapshot and self-test mode
As the developer, I run the app with a flag that renders every snapshot page with seed data and exits.
Acceptance:
- [self] `RESTEDM_SNAPSHOT=1` writes every page listed at the top of this file to `build/snapshots/` (`scripts/snap.sh`).
- [self] Seed data shows filled headers, parameters, a JSON response and a 404.
- [self] Every page renders in light and dark appearance (`<page>-dark.png`).
Status: done

### S-017 Toolbar instead of a custom URL bar
As the user, I find the method, URL and Send controls in the window toolbar, like other Mac document apps.
Screens: request-empty, request-filled
Acceptance:
- [snap] The window shows the document title and the controls in a unified toolbar.
- [snap] Command-L still focuses the URL field.
- [snap] A saved document opens with no focus ring; only a new, empty document focuses the URL field.
UX:
- Flow: open a request -> method and URL in the toolbar -> ⌘L focuses the URL -> Return or ⌘R sends -> the response replaces the pane
- Surface: window toolbar (global actions of the window, mac-design "Toolbars"); three groups: method + URL, request options (S-018), Send Request
- States: new empty request focuses the URL field; a saved request opens with nothing focused; while sending, Send Request turns into Stop Request
- Words: URL placeholder "Enter a URL", Send button "Send Request", tooltips "Send the request (⌘R)" and "Stop the request (⌘R)", method picker label "Method"
- Access: VoiceOver "Method, GET, pop-up button", "URL, text field"; the toolbar folds into the overflow menu when narrow, Send stays visible
Status: done

### S-018 Request options in the toolbar and Request menu
As the user, I reach Authorization, string encoding and Follow Redirects from the Request menu and a toolbar options menu, not from a bar on the bottom edge.
Screens: request-filled, authorization-sheet
Depends: S-017
Acceptance:
- [snap] The bottom options bar is gone; the window has no controls on its bottom edge.
- [snap] The toolbar shows a lock symbol that is closed with a username set; its tooltip names the user.
- [self] Request ▸ Authorization… (Option-Command-A) opens the sheet; Request ▸ Follow Redirects is a checkmark item.
UX:
- Flow: lock button or Request ▸ Authorization… (⌥⌘A) -> sheet -> OK or Return closes, Escape cancels; options menu or Request ▸ Text Encoding / Follow Redirects -> checkmark changes at once
- Surface: sheet for Authorization (one short task); a toolbar menu and the Request menu for Text Encoding and Follow Redirects (values on the request, menu checkmarks)
- States: lock open "Authorization…" without a username, lock closed with tooltip "Basic authorization as demo"; the sheet focuses Username only when it is empty
- Words: "Authorization…", "Text Encoding", "Follow Redirects", sheet title "Basic Authorization", toggles "Remember password" with the note "Saved as plain text in the request file." and "Send before the server asks"
- Access: opening and closing the sheet without typing leaves the request unedited; VoiceOver reads the lock as "Authorization"
Status: done

### S-019 Editor sections size to their content
As the user, I see headers, parameters and body take the space their content needs, without large empty bands.
Screens: request-filled, request-empty
Depends: S-018
Acceptance:
- [snap] Two header rows take two rows of height plus the Add button; parameters and body get the rest.
- [snap] With "Use Custom HTTP Body" off the body area shrinks to the toggle and one line saying parameters are sent.
- [snap] With more rows than fit, the whole column scrolls as one; the body editor keeps at least 120 pt.
- [snap] Settings opens with nothing focused.
Status: done

### S-010 See send errors in the response pane
As the user, when a request cannot be built (bad URL, bad JSON parameter), I see why in the response pane instead of a modal alert.
Screens: response-error
Acceptance:
- [snap] The pane shows the error with an icon, the failing part and a hint, styled like a network error.
- [self] Sending "http://" shows the error and no alert window opens.
UX:
- Flow: ⌘R with a URL that cannot be built -> the response pane shows why -> fix the URL -> ⌘R sends and the message goes away
- Surface: inline in the response pane (information next to the problem, no alert)
- States: request error: `ContentUnavailableView` "Unable to Send Request" with the reason and the fix; network error: status line "No Response" with the octagon icon once, the body area says what happened and how to fix it
- Words: "Enter a URL to send the request to.", "“http://” is not a valid URL. Check the host name for typos or spaces.", "Could not connect to the server. Check that it is running and that the URL and port are right."
- Access: the message is plain text VoiceOver reads; color always comes with the icon
Status: done

### S-011 See the final URL before sending
As the user, I see at the top of the request editor what will be sent after `{{name}}` substitution and query parameters.
Screens: request-filled
Depends: S-017
Acceptance:
- [snap] A secondary, monospaced line shows the resolved URL when it differs from the typed one.
- [snap] An unresolved `{{name}}` is marked in orange with "No value for name".
- [unit] The preview equals the URL `RequestBuilder` builds for the same request.
UX:
- Flow: type a URL with `{{id}}` or add a query parameter -> the line above the headers updates as you type
- Surface: inline line at the top of the request editor column (shows a value derived from what is on screen)
- States: hidden when the resolved URL equals the typed one; secondary monospaced "Sends to https://…" otherwise; orange triangle "No value for {{name}}" when a placeholder has no parameter
- Words: "Sends to", "No value for {{name}}"; the full URL in a tooltip when it is truncated in the middle
- Access: text is selectable; VoiceOver reads "Sends to" and the URL
Status: done

### S-012 Edit the body with highlighting
As the user, I type a JSON or XML body in an editor with monospaced text, syntax highlighting and an invalid-JSON marker.
Screens: request-filled
Acceptance:
- [snap] JSON keys, strings and numbers use the same colors as the response body.
- [snap] Invalid JSON with a JSON Content-Type shows "Invalid JSON at line N" under the editor.
- [manual] Smart quotes and autocorrection never change the body.
Status: done

### S-013 Copy parts of the response
As the user, I copy the body, a header or the status line from the response pane.
Screens: response-body, response-headers
Acceptance:
- [snap] A Copy button in the response tab bar copies the shown tab as text.
- [self] Edit ▸ Copy Response Body (Shift-Command-C) puts the raw body on the pasteboard.
- [self] View ▸ Response Body, Response Headers and Request (Option-Command-1, 2, 3) switch the tabs.
Status: todo

### S-014 Reorder and duplicate rows
As the user, I drag header and parameter rows to reorder them and duplicate or delete a row from its context menu.
Screens: request-filled
Acceptance:
- [manual] Dragging a row changes the JSON key order that is sent.
- [snap] The row context menu shows Duplicate, Enable/Disable and Delete.
Status: todo

### S-015 Paste headers as text
As the user, I paste lines like `Accept: application/json` into the headers list and they become rows.
Screens: request-filled
Depends: S-014
Acceptance:
- [unit] "Name: value" lines parse into rows; blank and malformed lines are skipped.
- [self] Pasting three header lines adds three rows.
Status: todo

### S-016 Tell methods apart at a glance
As the user, I see the method in a color that matches its kind in the URL bar and response summary.
Screens: request-filled, response-body
Acceptance:
- [snap] GET, POST, PUT, PATCH and DELETE each have their own tint; others use the accent color.
- [snap] Text on the tint uses the on-accent token and passes 4.5:1 in light and dark mode.
Status: todo

## M3 Environments

### S-020 Store environments
As the user, I keep named environments with variables in Application Support, shared by all documents.
Acceptance:
- [unit] Environments round-trip through JSON with variable order and enabled flags.
- [unit] A missing or corrupt file starts with no environments and does not crash.
Status: todo

### S-021 Edit environments
As the user, I add, rename and delete environments and edit their variables in an Environments window.
Screens: environments
Depends: S-020
Acceptance:
- [snap] Sidebar of environments, variable rows on the right, using the same row editor as headers.
- [self] Window ▸ Environments (Shift-Command-E) opens the window.
Status: todo

### S-022 Switch the active environment
As the user, I pick the active environment from a toolbar menu in any request window.
Screens: request-filled
Depends: S-021
Acceptance:
- [snap] The toolbar shows the active environment name, or "No Environment".
- [self] Changing it in one window updates every open window.
Status: todo

### S-023 Fill URL, headers and body from the environment
As the user, I write `{{base}}/users` and the active environment fills it in URL, header values and body.
Depends: S-022
Acceptance:
- [unit] An enabled parameter wins over an environment variable of the same name, so RESTed documents behave as before.
- [unit] Unknown `{{name}}` stays as typed and is reported by the URL preview.
- [unit] The saved `.request` file keeps the `{{name}}` text.
Status: todo

## M4 History

### S-030 Record every send
As the user, every finished send is saved to a local history with the request snapshot and a response summary.
Acceptance:
- [unit] History keeps the newest 500 entries and survives a restart.
- [unit] Stored passwords are left out of history entries.
Status: todo

### S-031 Browse the history
As the user, I open Window ▸ History and see sends grouped by day, with method, URL, status and time.
Screens: history
Depends: S-030
Acceptance:
- [snap] A list with day headers, method tint, status color and a search field.
- [self] Shift-Command-H opens the window.
Status: todo

### S-032 Reopen a history entry
As the user, I double-click a history entry and get a new untitled document with that request and its response shown.
Screens: history, response-body
Depends: S-031
Acceptance:
- [self] The new window shows the stored response without sending again.
- [manual] Command-R in it sends the request again.
Status: todo

### S-033 Clear the history
As the user, I clear all history from the History window after a confirmation.
Screens: history
Depends: S-031
Acceptance:
- [snap] The confirmation names how many entries will be removed.
- [unit] Clearing empties the stored file.
Status: todo

## M5 cURL

### S-040 Copy a request as cURL
As the user, I choose Request ▸ Copy as cURL and paste a working `curl` command into Terminal.
Depends: S-023
Acceptance:
- [unit] Method, headers, body, Basic auth and redirects map to `-X`, `-H`, `--data-binary`, `-u` and `-L`, shell-quoted.
- [unit] The command uses the URL after environment substitution.
- [manual] The copied command returns the same response in Terminal.
Status: todo

### S-041 Paste a cURL command as a request
As the user, I paste a `curl` command into the URL field and it fills method, URL, headers and body.
Screens: curl-import
Acceptance:
- [unit] Parses `-X`, `-H`, `-d`, `--data-raw`, `--data-binary`, `-u`, `-L`, line continuations and both quote styles.
- [snap] A confirmation shows what will replace the current request; Escape keeps it.
Status: todo

### S-042 Create a document from cURL
As the user, I choose File ▸ New Request from cURL… and get a new window filled from the pasteboard.
Screens: curl-import
Depends: S-041
Acceptance:
- [self] With a curl command on the pasteboard the new window opens filled; otherwise the menu item is disabled.
Status: todo

## M6 Finish

### S-051 Keyboard-only round trip
As the user, I compose, send and read a request without the mouse.
Acceptance:
- [manual] Tab order runs method, URL, headers, parameters, body, options; Command-Option-1/2/3 switch response tabs.
Status: todo

### S-052 Accessibility labels
As the user with VoiceOver, every control in the window has a spoken name.
Acceptance:
- [manual] VoiceOver names the row checkboxes ("Enable header Accept"), the remove buttons and the status line.
Status: todo

## Dropped
- Editing OAuth and JSONP settings: kept in the file only (brief, not in version one).
- Collections, workspaces, sync, sharing and teams: one user, files in Finder are the collection.
- Response scripts, tests and assertions.
- GraphQL, WebSocket and gRPC.
