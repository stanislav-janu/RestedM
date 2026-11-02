# Fix log

## Opening Authorization marked the request as edited
- Symptom: opening the Authorization sheet and closing it without typing showed "Edited" in the title, and closing the window asked to save.
- Cause: the sheet's fields were bound straight to the document. SwiftUI text fields write their value back when they appear, and every write through a `DocumentGroup` binding counts as an edit, even when the value is the same.
- Fix: the sheet edits a `Credentials` copy and writes it to the request only on OK, and only when it differs.
- Rule: a sheet or popover edits a copy of document values and writes back only a real change on confirm; never bind its fields straight to the document.

## A new request did not focus its URL field after the toolbar move
- Symptom: after the URL field moved into the window toolbar, a new request opened with a toolbar button focused instead of the URL field.
- Cause: SwiftUI `@FocusState` does not reach a text field inside a window toolbar, and the window was read before the view was in it.
- Fix: `URLFieldFocus` finds the toolbar's AppKit text field by its prompt and makes it first responder, reading the window again on each retry.
- Rule: focus a toolbar text field through AppKit (`makeFirstResponder`); check it with real key presses, because SwiftUI menu items report a stale `isEnabled` and carry no action to call.
