import AppKit
import RestedCore

/// Checks that need the running app, started by `scripts/selftest.sh`:
///   RESTEDM_SELFTEST=1 RestedM.app/Contents/MacOS/RestedM
/// prints PASS or FAIL per check and exits with 0 only when every check passes.
/// Like snapshots, it never edits or saves a document.
@MainActor
enum SelfTest {
    static let isActive = ProcessInfo.processInfo.environment["RESTEDM_SELFTEST"] == "1"

    private static var failures = 0

    static func run() {
        guard isActive else {
            return
        }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            checkMenus()
            checkSymbols()
            await checkSeedDocument()
            await checkNewRequestFocus()
            print("SELFTEST \(failures == 0 ? "PASS" : "FAIL") (\(failures) failed)")
            let code: Int32 = failures == 0 ? 0 : 1
            for document in NSDocumentController.shared.documents {
                document.close()
            }
            exit(code)
        }
    }

    static func check(_ name: String, _ condition: Bool) {
        if condition {
            print("PASS \(name)")
        } else {
            failures += 1
            print("FAIL \(name)")
        }
    }

    /// Focus only exists in the key window. When macOS keeps another app in front, say so instead of failing.
    static func checkWhenKey(_ window: NSWindow?, _ name: String, _ condition: @autoclosure () -> Bool) {
        guard window?.isKeyWindow == true else {
            print("SKIP \(name): the window is not key, so focus cannot be checked")
            return
        }
        check(name, condition())
    }

    /// Finds a menu item by title anywhere in the main menu.
    static func menuItem(_ title: String) -> NSMenuItem? {
        menuItem(title, in: NSApp.mainMenu)
    }

    private static func menuItem(_ title: String, in menu: NSMenu?) -> NSMenuItem? {
        for item in menu?.items ?? [] {
            if item.title == title {
                return item
            }
            if let found = menuItem(title, in: item.submenu) {
                return found
            }
        }
        return nil
    }

    private static func checkMenus() {
        let expected: [(title: String, key: String, modifiers: NSEvent.ModifierFlags)] = [
            ("Send Request", "r", [.command]),
            ("Select URL Field", "l", [.command]),
            ("Save Last Request & Response…", "s", [.command, .option]),
            ("Authorization…", "a", [.command, .option]),
            ("Copy Response Body", "c", [.command, .shift]),
            ("Response Body", "1", [.command, .option]),
            ("Response Headers", "2", [.command, .option]),
            ("Sent Request", "3", [.command, .option]),
        ]
        for entry in expected {
            let item = menuItem(entry.title)
            check("menu \(entry.title) exists", item != nil)
            check(
                "menu \(entry.title) uses its shortcut (has \"\(item?.keyEquivalent ?? "")\" \(item?.keyEquivalentModifierMask.rawValue ?? 0))",
                // macOS moves digit shortcuts to the key in the same place on layouts where
                // digits need Shift (Czech ⌥⌘1 shows as ⌥⌘+), so only the modifiers must match.
                (item?.keyEquivalent == entry.key || entry.key.allSatisfy(\.isNumber) && item?.keyEquivalent.isEmpty == false)
                    && item?.keyEquivalentModifierMask == entry.modifiers
            )
        }
    }

    /// Opens the seed request and checks what happens to it in a window.
    private static func checkSeedDocument() async {
        check("menu Follow Redirects exists", menuItem("Follow Redirects") != nil)
        check("menu Text Encoding exists", menuItem("Text Encoding") != nil)
        guard let url = try? SeedData.writeRequestFile(),
              let document = try? await NSDocumentController.shared.openDocument(withContentsOf: url, display: true).0 else {
            check("seed request opens", false)
            return
        }
        try? await Task.sleep(for: .seconds(1))
        guard let session = Snapshot.sessions.last else {
            check("seed request window registers its session", false)
            return
        }
        session.showsAuthorization = true
        try? await Task.sleep(for: .seconds(0.8))
        check("authorization sheet opens", session.window?.attachedSheet != nil)
        session.showsAuthorization = false
        try? await Task.sleep(for: .seconds(0.8))
        check("opening and closing Authorization leaves the request unedited", !document.isDocumentEdited)

        // ⌘L focuses the URL field in the toolbar: the field editor then holds the URL.
        if let window = session.window {
            Snapshot.bringForward(window, within: 6)
        }
        if let item = menuItem("Select URL Field"), let action = item.action {
            NSApp.sendAction(action, to: item.target, from: item)
            try? await Task.sleep(for: .seconds(0.4))
        }
        let editor = session.window?.firstResponder as? NSTextView
        checkWhenKey(session.window, "⌘L focuses the URL field", editor?.isFieldEditor == true && editor?.string == SeedData.request.urlString)

        var invalid = SeedData.request
        invalid.urlString = "http://"
        session.send(invalid)
        try? await Task.sleep(for: .seconds(0.5))
        check("an invalid URL shows its error in the response pane", session.buildError?.contains("not a valid URL") == true)
        check("an invalid URL opens no alert", NSApp.modalWindow == nil && !NSApp.windows.contains { $0 is NSPanel && $0.isVisible })
        session.buildError = nil
    }

    /// A new, empty request opens with its URL field focused, ready for typing.
    private static func checkNewRequestFocus() async {
        let before = Snapshot.sessions.count
        NSDocumentController.shared.newDocument(nil)
        try? await Task.sleep(for: .seconds(1))
        guard Snapshot.sessions.count > before, let window = Snapshot.sessions.last?.window else {
            check("a new request opens a window", false)
            return
        }
        Snapshot.bringForward(window, within: 6)
        let editor = window.firstResponder as? NSTextView
        checkWhenKey(window, "a new request focuses its URL field", editor?.isFieldEditor == true && editor?.string.isEmpty == true)
    }

    private static func checkSymbols() {
        let symbols = ["paperplane.fill", "stop.fill", "lock.fill", "lock.open", "minus.circle", "plus", "exclamationmark.triangle", "xmark.octagon.fill", "slider.horizontal.3", "document.on.document", "document.on.clipboard", "line.3.horizontal"]
        for name in symbols {
            check("symbol \(name) exists", NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil)
        }
    }
}
