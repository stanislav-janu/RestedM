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
        ]
        for entry in expected {
            let item = menuItem(entry.title)
            check("menu \(entry.title) exists", item != nil)
            check(
                "menu \(entry.title) uses its shortcut",
                item?.keyEquivalent == entry.key && item?.keyEquivalentModifierMask == entry.modifiers
            )
        }
    }

    private static func checkSymbols() {
        let symbols = ["paperplane.fill", "stop.fill", "lock.fill", "lock.open", "minus.circle", "plus", "exclamationmark.triangle", "xmark.octagon.fill"]
        for name in symbols {
            check("symbol \(name) exists", NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil)
        }
    }
}
