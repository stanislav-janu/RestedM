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
            Divider()
            optionsBar
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
            .padding(.horizontal, 12)
            .padding(.top, 8)

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
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
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
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(nsColor: .separatorColor)))
                .padding(.horizontal, 12)
            if request.usesCustomBody && request.customBodyIsIgnored {
                Label("\(request.method) requests cannot carry a body. Parameters are sent in the URL instead.", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 12)
            }
            Spacer(minLength: 8)
        }
    }

    private var optionsBar: some View {
        HStack(spacing: 12) {
            Button {
                showsAuthorization = true
            } label: {
                Label(request.hasCredentials ? "Authorization: \(request.username)" : "Authorization…", systemImage: request.hasCredentials ? "lock.fill" : "lock.open")
            }
            .lineLimit(1)

            Picker("Encoding", selection: $request.stringEncoding) {
                Text("UTF-8").tag(String.Encoding.utf8.rawValue)
                Text("ISO Latin-1").tag(String.Encoding.isoLatin1.rawValue)
                Text("ASCII").tag(String.Encoding.ascii.rawValue)
                if ![String.Encoding.utf8, .isoLatin1, .ascii].map(\.rawValue).contains(request.stringEncoding) {
                    Text("Encoding \(request.stringEncoding)").tag(request.stringEncoding)
                }
            }
            .fixedSize()

            Spacer()

            Toggle("Follow Redirects", isOn: $request.followRedirects)
        }
        .controlSize(.small)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        section(title, accessory: { EmptyView() }, content: content)
    }

    private func section<Accessory: View, Content: View>(
        _ title: String,
        @ViewBuilder accessory: () -> Accessory,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                accessory()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            content()
        }
    }
}

struct AuthorizationSheet: View {
    @Binding var request: RestRequest
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Authorization")
                .font(.title3.bold())
            Form {
                TextField("Username", text: $request.username)
                SecureField("Password", text: $request.password)
                Toggle("Remember password (stored as plain text in the document)", isOn: $request.storePassword)
                Toggle("Send credentials before the authentication challenge", isOn: $request.presentBeforeChallenge)
            }
            HStack {
                Button("Clear", role: .destructive) {
                    request.username = ""
                    request.password = ""
                    request.storePassword = false
                    request.presentBeforeChallenge = false
                }
                .disabled(!request.hasCredentials && request.password.isEmpty)
                Spacer()
                Button("OK") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 440)
    }
}
