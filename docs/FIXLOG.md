# Fix log

## Opening Authorization marked the request as edited
- Symptom: opening the Authorization sheet and closing it without typing showed "Edited" in the title, and closing the window asked to save.
- Cause: the sheet's fields were bound straight to the document. SwiftUI text fields write their value back when they appear, and every write through a `DocumentGroup` binding counts as an edit, even when the value is the same.
- Fix: the sheet edits a `Credentials` copy and writes it to the request only on OK, and only when it differs.
- Rule: a sheet or popover edits a copy of document values and writes back only a real change on confirm; never bind its fields straight to the document.
