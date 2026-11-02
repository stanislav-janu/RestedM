import RestedCore
import SwiftUI

/// Headers, parameters and body in one column. Lists take the height of their rows,
/// the body editor takes the rest, and the whole column scrolls when it runs out of room.
struct RequestEditor: View {
    @Binding var request: RestRequest

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ResolvedURLLine(request: request)
                    section("Headers") {
                        KeyValueEditor(
                            rows: $request.headers,
                            namePlaceholder: "Header Field",
                            valuePlaceholder: "Header Value",
                            nameSuggestions: { _ in HeaderCatalog.names },
                            valueSuggestions: { HeaderCatalog.suggestions(for: $0) },
                            parsePasted: HeaderText.rows(from:)
                        )
                    }
                    Divider()
                    layoutPicker
                    if layout.wrappedValue != .body {
                        parametersSection
                    }
                    if layout.wrappedValue == .both {
                        Divider()
                    }
                    if layout.wrappedValue != .parameters {
                        bodySection
                    }
                }
                .frame(minHeight: proxy.size.height, alignment: .top)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private var layout: Binding<ParamBodyLayout> {
        Binding(
            get: { ParamBodyLayout(rawValue: request.paramBodyUIChoice) ?? .both },
            set: { request.paramBodyUIChoice = $0.rawValue }
        )
    }

    private var layoutPicker: some View {
        Picker("Show", selection: layout) {
            ForEach(ParamBodyLayout.allCases) { layout in
                Text(layout.title).tag(layout)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Space.pane)
        .padding(.top, Space.md)
    }

    private var parametersSection: some View {
        section("Parameters", accessory: {
            Picker("Encoding", selection: $request.parametersEncoding) {
                Text("Form-encoded").tag(ParametersEncoding.form)
                Text("JSON-encoded").tag(ParametersEncoding.json)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            .controlSize(.small)
        }) {
            KeyValueEditor(
                rows: $request.parameters,
                namePlaceholder: "Parameter Name",
                valuePlaceholder: "Parameter Value",
                nameSuggestions: nil,
                valueSuggestions: nil
            )
            Text("Use {{name}} in the URL to insert a parameter's value into the path.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Space.pane)
                .padding(.bottom, Space.sm)
        }
    }

    @ViewBuilder
    private var bodySection: some View {
        section("HTTP Body", accessory: {
            Toggle("Use Custom HTTP Body", isOn: $request.usesCustomBody)
                .controlSize(.small)
        }) {
            if request.usesCustomBody {
                BodyEditor(text: $request.body)
                    .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: Radius.xs))
                    .overlay(RoundedRectangle(cornerRadius: Radius.xs).stroke(Color(nsColor: .separatorColor)))
                    .frame(minHeight: Metrics.bodyEditorMinHeight, maxHeight: .infinity)
                    .padding(.horizontal, Space.pane)
                if let line = jsonErrorLine {
                    Label(line > 0 ? "Invalid JSON at line \(line)" : "Invalid JSON", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(Palette.warning)
                        .padding(.horizontal, Space.pane)
                }
                if request.customBodyIsIgnored {
                    Label("\(request.method) requests cannot carry a body. Parameters are sent in the URL instead.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(Palette.warning)
                        .padding(.horizontal, Space.pane)
                }
            } else {
                Text(parametersDestination)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Space.pane)
            }
        }
        .padding(.bottom, Space.md)
        .frame(maxHeight: request.usesCustomBody ? .infinity : nil, alignment: .top)
    }

    /// The line of the first JSON error, when the body is meant to be JSON: it starts like JSON
    /// or an enabled Content-Type header says JSON.
    private var jsonErrorLine: Int? {
        let declaresJSON = request.headers.contains {
            $0.enabled && $0.name.caseInsensitiveCompare("Content-Type") == .orderedSame && $0.value.lowercased().contains("json")
        }
        guard declaresJSON || JSONPrettyPrinter.looksLikeJSON(request.body) else {
            return nil
        }
        return JSONPrettyPrinter.errorLine(in: request.body)
    }

    /// Where the parameters go while no custom body is set, as RequestBuilder decides.
    private var parametersDestination: String {
        request.sendsParametersInURL
            ? "\(request.method) sends the parameters in the URL."
            : "The parameters are sent as the body."
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        section(title, accessory: { EmptyView() }, content: content)
    }

    private func section<Accessory: View, Content: View>(
        _ title: String,
        @ViewBuilder accessory: () -> Accessory,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                accessory()
            }
            .padding(.horizontal, Space.pane)
            .padding(.top, Space.md)
            content()
        }
    }
}

/// What the request will be sent to after placeholders and query parameters, shown only when
/// that differs from the typed URL, plus a warning for each placeholder without a value.
struct ResolvedURLLine: View {
    let request: RestRequest

    var body: some View {
        let builder = RequestBuilder(request: request, options: SendOptions())
        let resolved = builder.resolvedURL
        let missing = builder.unresolvedPlaceholders
        if (resolved != nil && resolved != request.urlString.trimmingCharacters(in: .whitespacesAndNewlines)) || !missing.isEmpty {
            VStack(alignment: .leading, spacing: Space.xs) {
                if let resolved, missing.isEmpty {
                    HStack(alignment: .firstTextBaseline, spacing: Space.sm) {
                        Text("Sends to")
                            .foregroundStyle(.secondary)
                        Text(resolved)
                            .font(.system(.callout, design: .monospaced))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .textSelection(.enabled)
                            .help(resolved)
                    }
                    .accessibilityElement(children: .combine)
                }
                ForEach(missing, id: \.self) { name in
                    Label("No value for {{\(name)}}", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(Palette.warning)
                }
            }
            .font(.callout)
            .padding(.horizontal, Space.pane)
            .padding(.top, Space.md)
        }
    }
}

/// Edits a copy of the credentials, so opening and closing the sheet never edits the request.
struct AuthorizationSheet: View {
    @Binding var request: RestRequest
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Credentials

    init(request: Binding<RestRequest>) {
        _request = request
        _draft = State(initialValue: Credentials(request.wrappedValue))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.lg) {
            Text("Basic Authorization")
                .font(.title3.bold())
            Form {
                TextField("Username", text: $draft.username)
                SecureField("Password", text: $draft.password)
                Toggle(isOn: $draft.storePassword) {
                    Text("Remember password")
                    Text("Saved as plain text in the request file.")
                }
                Toggle("Send before the server asks", isOn: $draft.presentBeforeChallenge)
            }
            HStack {
                Button("Clear", role: .destructive) {
                    draft = Credentials()
                }
                .disabled(draft == Credentials())
                Spacer()
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button("OK") {
                    if draft != Credentials(request) {
                        draft.apply(to: &request)
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(Space.xl)
        .frame(width: Metrics.sheetWidth)
        .noInitialFocus(!draft.username.isEmpty)
    }
}

/// The Basic authorization fields of a request.
struct Credentials: Equatable {
    var username = ""
    var password = ""
    var storePassword = false
    var presentBeforeChallenge = false

    init() {}

    init(_ request: RestRequest) {
        username = request.username
        password = request.password
        storePassword = request.storePassword
        presentBeforeChallenge = request.presentBeforeChallenge
    }

    func apply(to request: inout RestRequest) {
        request.username = username
        request.password = password
        request.storePassword = storePassword
        request.presentBeforeChallenge = presentBeforeChallenge
    }
}
