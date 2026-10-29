import RestedCore
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let restedRequest = UTType(exportedAs: "cz.goodagency.restedm.request", conformingTo: .xml)
}

struct RequestDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.restedRequest]
    }

    var request: RestRequest

    init() {
        request = RestRequest()
        request.paramBodyUIChoice = UserDefaults.standard.integer(forKey: Preferences.paramBodyUIChoice)
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        request = try RequestFile.decode(data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: try RequestFile.encode(request))
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// SwiftUI creates an untitled document even when launched to open files.
    /// Close it once the opened files are in, so only those windows remain.
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let documents = NSDocumentController.shared.documents
            guard documents.contains(where: { $0.fileURL != nil }) else {
                return
            }
            for document in documents where document.fileURL == nil && !document.isDocumentEdited {
                document.close()
            }
        }
    }
}

@main
struct RestedMApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        Preferences.registerDefaults()
    }

    var body: some Scene {
        DocumentGroup(newDocument: RequestDocument()) { file in
            RequestWindow(request: file.$document.request)
        }
        .defaultSize(width: 1200, height: 800)
        .commands {
            TextEditingCommands()
            RequestCommands()
        }

        Settings {
            PreferencesView()
        }
    }
}

struct RequestActions {
    var send: () -> Void
    var focusURL: () -> Void
    var exportLast: () -> Void
    var canExport: Bool
    var isSending: Bool
}

struct RequestActionsKey: FocusedValueKey {
    typealias Value = RequestActions
}

extension FocusedValues {
    var requestActions: RequestActions? {
        get { self[RequestActionsKey.self] }
        set { self[RequestActionsKey.self] = newValue }
    }
}

struct RequestCommands: Commands {
    @FocusedValue(\.requestActions) private var actions

    var body: some Commands {
        CommandGroup(after: .saveItem) {
            Button("Save Last Request & Response…") {
                actions?.exportLast()
            }
            .keyboardShortcut("s", modifiers: [.command, .option])
            .disabled(actions?.canExport != true)
        }
        CommandMenu("Request") {
            Button(actions?.isSending == true ? "Stop Request" : "Send Request") {
                actions?.send()
            }
            .keyboardShortcut("r")
            .disabled(actions == nil)

            Button("Select URL Field") {
                actions?.focusURL()
            }
            .keyboardShortcut("l")
            .disabled(actions == nil)
        }
    }
}
