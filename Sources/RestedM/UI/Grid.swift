import SwiftUI

/// The spacing scale. Every padding and spacing sits on a 4 pt grid.
enum Space {
    static let hairline: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    /// Inset of pane content from the pane edges. Dense editor panes use 12, sheets use `xl`.
    static let pane: CGFloat = 12
}
