import SwiftUI

/// The method of a request in its own tint, on a light wash of that tint.
struct MethodBadge: View {
    let method: String

    var body: some View {
        Text(method)
            .font(.system(.caption, design: .monospaced).bold())
            .foregroundStyle(MethodColors.color(for: method))
            .padding(.horizontal, Space.sm)
            .padding(.vertical, Space.hairline)
            .background(MethodColors.color(for: method).opacity(0.15), in: RoundedRectangle(cornerRadius: Radius.xs))
    }
}
