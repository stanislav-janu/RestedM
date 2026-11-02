# RestedM design system

RestedM keeps Apple's look and the Mac's own accent color. Tokens cover only what the system does not: status and syntax colors, text on accent fills, spacing, radii and fixed sizes. Token files live in `Sources/RestedM/UI/`. Views use tokens, never raw values.

## Theme.swift

- `Palette.accent`: the system accent (`Color.accentColor`). Use `.tint` or this token; never a hex accent.
- `Palette.onAccent`: text and symbols on an accent fill (the method badge). It is dark on light accents (yellow, green) and white otherwise. Never use a fixed `.white` on the accent.
- `Palette.accentText`: accent-colored text, deeper in light mode and lighter in dark mode.
- `Palette.status(code)` and `StatusColors`: 2xx success, 3xx redirect, 4xx client error, 5xx and network errors. Always show the status text or an icon next to the color.
- `Palette.warning`: inline warnings, such as a custom body that GET ignores. Pair it with `exclamationmark.triangle`.
- `CodeColors`: syntax colors for code on `textBackgroundColor`: `key`, `string`, `number`, `literal` and `headerName`. Request body highlighting uses the same tokens as the response.

Rules:
- Every custom color has four values: light, dark, and a stronger one of each for Increase Contrast (`NSColor(light:dark:highContrastLight:highContrastDark:)`). Each passes 4.5:1 on the text background, and the high-contrast values pass 7:1.
- Never redefine or copy a semantic color (`.separator` as text, a label color as a fill).
- Text uses `.primary`, `.secondary`, `.tertiary`; backgrounds use system colors (`textBackgroundColor` for code panes).

## Grid.swift

`Space`: `hairline 2`, `xs 4`, `sm 8`, `md 12`, `lg 16`, `xl 20`, `pane 12`.

- `pane` is the inset of editor and response content from the pane edges. The window is dense, so panes use 12 rather than 20.
- Sheets use `xl` margins and `lg` between groups.
- `sm` between related controls in a row, `md` between groups in a row, `xs` between list rows.
- Every value sits on the 4 pt grid. Control heights come from `.controlSize`.

## Radius.swift

`Radius.xs 6`: chips, badges, and framed text areas that sit next to text fields, so they match the system text field corners. Inner corners are concentric: inner radius = outer radius - inset.

## Layout.swift

Window minimum (880 × 520), editor and response column widths, method picker width, row name column limits and the sheet width (440). A new fixed size goes here with a name, not inline in a view.

## Controls and motion

- Use Apple's controls. Style one with `ButtonStyle` or `ToggleStyle`; never rebuild a control from shapes.
- One prominent button per window: Send Request.
- A new response replaces the previous one at once, because speed wins. Animations go through a `Motion.swift` token file with named curves that respect Reduce Motion.

## Check

This finds no hits outside `Sources/RestedM/UI/`:

```bash
grep -rnE 'cornerRadius: [0-9]{1,2}\b|duration: [0-9]|\.spring\(response|\.snappy\b|\.easeInOut|\.easeOut\(|Color\(hex:|Color\(red:|padding\([0-9]|spacing: [1-9]' Sources/RestedM | grep -v 'Sources/RestedM/UI/'
```
