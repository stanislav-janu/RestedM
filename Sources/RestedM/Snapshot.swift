import AppKit
import IOKit.pwr_mgt
import SwiftUI

/// Screenshot mode for agents and reviews, started by `scripts/snap.sh`:
///   RESTEDM_SNAPSHOT=<dir> RestedM.app/Contents/MacOS/RestedM
/// writes <page>-light.png and <page>-dark.png for every page, then quits.
/// RESTEDM_SNAPSHOT_PAGES=response-body,settings limits the pages.
/// The run only sets view state (response, tab, sheet). It never edits or saves a document.
@MainActor
enum Snapshot {
    enum Page: String, CaseIterable {
        case requestEmpty = "request-empty"
        case requestFilled = "request-filled"
        case responseBody = "response-body"
        case responseHeaders = "response-headers"
        case responseSent = "response-sent"
        case response404 = "response-404"
        case responseError = "response-error"
        case requestInvalid = "request-invalid"
        case authorizationSheet = "authorization-sheet"
        case settings
    }

    static let directory = ProcessInfo.processInfo.environment["RESTEDM_SNAPSHOT"].flatMap { $0.isEmpty ? nil : $0 }

    static var isActive: Bool {
        directory != nil
    }

    /// Sessions of the windows open in an agent run, oldest first.
    private(set) static var sessions: [RequestSession] = []
    private static var openSettings: OpenSettingsAction?

    static func register(_ session: RequestSession, openSettings: OpenSettingsAction) {
        if !sessions.contains(where: { $0 === session }) {
            sessions.append(session)
        }
        self.openSettings = openSettings
    }

    static func run() {
        guard let directory else {
            return
        }
        let env = ProcessInfo.processInfo.environment
        let only = env["RESTEDM_SNAPSHOT_PAGES"].map { Set($0.split(separator: ",").map(String.init)) }
        let pages = Page.allCases.filter { only?.contains($0.rawValue) ?? true }
        // Each document gets its own window, whatever the Mac's tab preference says.
        NSWindow.allowsAutomaticWindowTabbing = false
        Task {
            keepDisplayAwake()
            try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
            try? await Task.sleep(for: .seconds(1.5))

            // An untitled document shows the empty request; the seed file shows the rest.
            // Launched without files, DocumentGroup may open no window, so make one.
            if sessions.isEmpty {
                NSDocumentController.shared.newDocument(nil)
                try? await Task.sleep(for: .seconds(1))
            }
            let empty = sessions.first
            var filled: RequestSession?
            if let url = try? SeedData.writeRequestFile() {
                _ = try? await NSDocumentController.shared.openDocument(withContentsOf: url, display: true)
                try? await Task.sleep(for: .seconds(1))
                filled = sessions.last.flatMap { $0 === empty ? nil : $0 }
            }

            // The first activation after launch takes longest; do it before the first capture.
            if let window = empty?.window {
                bringForward(window, within: 6)
            }
            for mode in ["light", "dark"] {
                NSApp.appearance = NSAppearance(named: mode == "light" ? .aqua : .darkAqua)
                for page in pages {
                    let path = "\(directory)/\(page.rawValue)-\(mode).png"
                    await show(page, empty: empty, filled: filled, path: path)
                }
            }
            print("SNAPSHOT done \(directory)")
            quit()
        }
    }

    private static func show(_ page: Page, empty: RequestSession?, filled: RequestSession?, path: String) async {
        let session = page == .requestEmpty ? empty : filled
        guard page == .settings || session != nil else {
            print("SNAPSHOT no window for \(page.rawValue)")
            return
        }
        switch page {
        case .requestEmpty, .requestFilled:
            session?.exchange = nil
            session?.buildError = nil
        case .responseBody, .responseHeaders, .responseSent:
            session?.buildError = nil
            session?.exchange = SeedData.okExchange
            session?.responseTab = page == .responseBody ? .body : page == .responseHeaders ? .headers : .request
        case .response404:
            session?.buildError = nil
            session?.exchange = SeedData.notFoundExchange
            session?.responseTab = .body
        case .responseError:
            session?.buildError = nil
            session?.exchange = SeedData.errorExchange
            session?.responseTab = .body
        case .requestInvalid:
            session?.exchange = nil
            var invalid = SeedData.request
            invalid.urlString = "http://"
            session?.send(invalid)
        case .authorizationSheet:
            session?.exchange = nil
            session?.buildError = nil
            session?.showsAuthorization = true
        case .settings:
            openSettings?()
        }
        try? await Task.sleep(for: .seconds(0.8))

        switch page {
        case .authorizationSheet:
            capture(session?.window?.attachedSheet, to: path)
            session?.showsAuthorization = false
            try? await Task.sleep(for: .seconds(0.5))
        case .settings:
            let documentWindows = sessions.compactMap(\.window)
            let settings = NSApp.windows.first { window in
                window.isVisible && !window.isSheet && !documentWindows.contains { $0 === window }
            }
            capture(settings, to: path)
            settings?.close()
        default:
            capture(session?.window, to: path)
        }
    }

    /// Captures the real window with screencapture, so materials look as on screen.
    /// That needs Screen Recording permission for the process that started the app.
    private static func capture(_ window: NSWindow?, to path: String) {
        guard let window else {
            print("SNAPSHOT no window for \(path)")
            return
        }
        if !bringForward(window, within: 3) {
            print("SNAPSHOT warning: \(path) captured while the window is not key")
        }
        try? FileManager.default.removeItem(atPath: path)
        // The first capture of a run sometimes misses the window. Try three times.
        for _ in 1...3 {
            let shot = Process()
            shot.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            shot.arguments = ["-x", "-o", "-l", String(window.windowNumber), path]
            try? shot.run()
            shot.waitUntilExit()
            if FileManager.default.fileExists(atPath: path) {
                print("SNAPSHOT \(path)")
                return
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        print("SNAPSHOT failed \(path): allow Screen Recording for the app that started RestedM")
    }

    /// Makes the window key in the active app, like a window someone is using:
    /// real accent colors and colored traffic lights. Returns whether that worked in time.
    @discardableResult
    private static func bringForward(_ window: NSWindow, within seconds: TimeInterval) -> Bool {
        // Another app can hide this one while snapshots run. Hidden windows cannot be captured.
        if NSApp.isHidden {
            NSApp.unhideWithoutActivation()
        }
        NSApp.activate()
        (window.sheetParent ?? window).makeKeyAndOrderFront(nil)
        // macOS ignores activate() while the person works in another app. An Apple Event
        // from osascript still brings the app forward.
        if !NSApp.isActive {
            let script = Process()
            script.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            script.arguments = ["-e", "tell application id \"\(Bundle.main.bundleIdentifier ?? "")\" to activate"]
            // No waitUntilExit: the event comes back to this app, so the run loop below must answer it.
            try? script.run()
        }
        let deadline = Date().addingTimeInterval(seconds)
        repeat {
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        } while !(NSApp.isActive && window.isKeyWindow) && Date() < deadline
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        return window.isKeyWindow
    }

    /// A sleeping display gives screencapture nothing. The assertions end when the run quits.
    private static func keepDisplayAwake() {
        var activity: IOPMAssertionID = 0
        IOPMAssertionDeclareUserActivity("RestedM snapshots" as CFString, kIOPMUserActiveLocal, &activity)
        var awake: IOPMAssertionID = 0
        IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "RestedM snapshots" as CFString,
            &awake
        )
    }

    /// Closes everything without saving. Snapshot runs never edit a document, so nothing is lost.
    static func quit() {
        for window in NSApp.windows {
            if let sheet = window.attachedSheet {
                window.endSheet(sheet)
            }
        }
        for document in NSDocumentController.shared.documents {
            document.close()
        }
        NSApp.terminate(nil)
    }
}
