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
    /// Turns pasted text into rows; nil hides the Paste button.
    var parsePasted: ((String) -> [KeyValueRow])? = nil

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Space.xs) {
                ForEach($rows) { $row in
                    rowView($row)
                }
                if rows.isEmpty {
                    Text("No \(namePlaceholder.components(separatedBy: " ").first?.lowercased() ?? "row")s")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Space.md)
                }
            }
            .padding(.horizontal, Space.pane)
            .padding(.vertical, Space.xs)
            HStack {
                Button {
                    rows.append(KeyValueRow())
                } label: {
                    Label("Add", systemImage: "plus")
                }
                if let parsePasted {
                    Button {
                        if let text = NSPasteboard.general.string(forType: .string) {
                            rows.append(contentsOf: parsePasted(text))
                        }
                    } label: {
                        Label("Paste", systemImage: "document.on.clipboard")
                    }
                    .help("Add one row for each “Name: value” line on the clipboard")
                }
                Spacer()
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .padding(.horizontal, Space.pane)
            .padding(.bottom, Space.sm)
        }
    }

    private func rowView(_ row: Binding<KeyValueRow>) -> some View {
        HStack(spacing: Space.sm) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary)
                .frame(width: Space.md)
                .contentShape(Rectangle())
                .help("Drag to change the order")
                .draggable(row.wrappedValue.id.uuidString) {
                    Text(row.wrappedValue.name.isEmpty ? namePlaceholder : row.wrappedValue.name)
                }
                .accessibilityHidden(true)
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
            .frame(minWidth: Metrics.rowNameMinWidth, maxWidth: Metrics.rowNameMaxWidth)
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
            .help("Remove this row")
        }
        .opacity(row.wrappedValue.enabled ? 1 : 0.55)
        .dropDestination(for: String.self) { items, _ in
            guard let id = items.first.flatMap(UUID.init(uuidString:)) else {
                return false
            }
            move(id, to: row.wrappedValue.id)
            return true
        }
        .contextMenu {
            Button("Duplicate") {
                duplicate(row.wrappedValue)
            }
            Button(row.wrappedValue.enabled ? "Disable" : "Enable") {
                row.wrappedValue.enabled.toggle()
            }
            Divider()
            Button("Delete", role: .destructive) {
                rows.removeAll { $0.id == row.wrappedValue.id }
            }
        }
    }

    private func duplicate(_ row: KeyValueRow) {
        guard let index = rows.firstIndex(where: { $0.id == row.id }) else {
            return
        }
        rows.insert(KeyValueRow(enabled: row.enabled, name: row.name, value: row.value), at: index + 1)
    }

    /// Moves a row to the place of another one, as a drag in a list does.
    private func move(_ id: KeyValueRow.ID, to target: KeyValueRow.ID) {
        guard id != target,
              let from = rows.firstIndex(where: { $0.id == id }),
              let to = rows.firstIndex(where: { $0.id == target }) else {
            return
        }
        rows.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
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
