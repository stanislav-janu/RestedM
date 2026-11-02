import RestedCore
import SwiftUI

struct RequestEditor: View {
    @Binding var request: RestRequest
    @Binding var showsAuthorization: Bool

    var body: some View {
        VStack(spacing: 0) {
            VSplitView {
                section("Headers") {
                    KeyValueEditor(
                        rows: $request.headers,
                        namePlaceholder: "Header Field",
                        valuePlaceholder: "Header Value",
                        nameSuggestions: { _ in HeaderCatalog.names },
                        valueSuggestions: { HeaderCatalog.suggestions(for: $0) }
                    )
                }
                .frame(minHeight: 90, idealHeight: 180, maxHeight: .infinity)

                parametersAndBody
                    .frame(minHeight: 160, maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
    }

    private var layout: Binding<ParamBodyLayout> {
        Binding(
            get: { ParamBodyLayout(rawValue: request.paramBodyUIChoice) ?? .both },
            set: { request.paramBodyUIChoice = $0.rawValue }
        )
    }

    @ViewBuilder
    private var parametersAndBody: some View {
        VStack(spacing: 0) {
            Picker("Show", selection: layout) {
                ForEach(ParamBodyLayout.allCases) { layout in
                    Text(layout.title).tag(layout)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, Space.pane)
            .padding(.top, Space.sm)

            switch layout.wrappedValue {
            case .both:
                VSplitView {
                    parametersSection
                        .frame(minHeight: 80, maxHeight: .infinity)
                    bodySection
                        .frame(minHeight: 80, maxHeight: .infinity)
                }
            case .parameters:
                parametersSection
            case .body:
                bodySection
            }
        }
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

    private var bodySection: some View {
        section("HTTP Body", accessory: {
            Toggle("Use Custom HTTP Body", isOn: $request.usesCustomBody)
                .controlSize(.small)
        }) {
            TextEditor(text: $request.body)
                .font(.system(size: 12, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: .textBackgroundColor))
                .disabled(!request.usesCustomBody)
                .opacity(request.usesCustomBody ? 1 : 0.5)
                .autocorrectionDisabled()
                .overlay(RoundedRectangle(cornerRadius: Radius.xs).stroke(Color(nsColor: .separatorColor)))
                .padding(.horizontal, Space.pane)
            if request.usesCustomBody && request.customBodyIsIgnored {
                Label("\(request.method) requests cannot carry a body. Parameters are sent in the URL instead.", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(Palette.warning)
                    .padding(.horizontal, Space.pane)
            }
            Spacer(minLength: 8)
        }
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
            .padding(.top, Space.sm)
            content()
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
