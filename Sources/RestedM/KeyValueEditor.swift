import AppKit
import RestedCore
import SwiftUI

/// Editable list of enabled/name/value rows used for headers and parameters.
struct KeyValueEditor: View {
    @Binding var rows: [KeyValueRow]
    let namePlaceholder: String
    let valuePlaceholder: String
    let nameSuggestions: ((String) -> [String])?
    let valueSuggestions: ((String) -> [String])?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach($rows) { $row in
                        rowView($row)
                    }
                    if rows.isEmpty {
                        Text("No \(namePlaceholder.components(separatedBy: " ").first?.lowercased() ?? "row")s")
                            .font(.callout)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }
            HStack {
                Button {
                    rows.append(KeyValueRow())
                } label: {
                    Label("Add", systemImage: "plus")
                }
                Spacer()
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
        }
    }

    private func rowView(_ row: Binding<KeyValueRow>) -> some View {
        HStack(spacing: 6) {
            Toggle("", isOn: row.enabled)
                .labelsHidden()
                .toggleStyle(.checkbox)
            Group {
                if let nameSuggestions {
                    ComboField(text: row.name, placeholder: namePlaceholder, items: nameSuggestions(row.wrappedValue.name))
                } else {
                    TextField(namePlaceholder, text: row.name)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .frame(minWidth: 120, maxWidth: 220)
            Group {
                if let valueSuggestions {
                    ComboField(text: row.value, placeholder: valuePlaceholder, items: valueSuggestions(row.wrappedValue.name))
                } else {
                    TextField(valuePlaceholder, text: row.value)
                        .textFieldStyle(.roundedBorder)
                }
            }
            Button {
                rows.removeAll { $0.id == row.wrappedValue.id }
            } label: {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.borderless)
            .help("Remove")
        }
        .opacity(row.wrappedValue.enabled ? 1 : 0.55)
    }
}

/// NSComboBox with inline autocompletion, as used by Rested's header table.
struct ComboField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let items: [String]

    func makeNSView(context: Context) -> NSComboBox {
        let comboBox = NSComboBox()
        comboBox.completes = true
        comboBox.usesDataSource = false
        comboBox.numberOfVisibleItems = 12
        comboBox.placeholderString = placeholder
        comboBox.delegate = context.coordinator
        comboBox.lineBreakMode = .byTruncatingTail
        comboBox.setContentHuggingPriority(.defaultLow, for: .horizontal)
        comboBox.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return comboBox
    }

    func updateNSView(_ comboBox: NSComboBox, context: Context) {
        context.coordinator.parent = self
        if comboBox.stringValue != text {
            comboBox.stringValue = text
        }
        if context.coordinator.items != items {
            context.coordinator.items = items
            comboBox.removeAllItems()
            comboBox.addItems(withObjectValues: items)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, NSComboBoxDelegate {
        var parent: ComboField
        var items: [String] = []

        init(parent: ComboField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let comboBox = notification.object as? NSComboBox else {
                return
            }
            parent.text = comboBox.stringValue
        }

        func comboBoxSelectionDidChange(_ notification: Notification) {
            guard let comboBox = notification.object as? NSComboBox,
                  let value = comboBox.objectValueOfSelectedItem as? String else {
                return
            }
            parent.text = value
        }
    }
}
