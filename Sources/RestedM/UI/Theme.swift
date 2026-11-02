import AppKit
import SwiftUI

/// Colors the system does not provide. The accent follows the Mac's own accent color.
enum Palette {
    static let accent = Color.accentColor

    /// Text and symbols on an accent fill: dark on light accents (yellow, green), white otherwise.
    static let onAccent = Color(nsColor: NSColor(name: "onAccent") { _ in
        NSColor.controlAccentColor.relativeLuminance > 0.4 ? NSColor(white: 0.09, alpha: 1) : .white
    })

    /// Accent-colored text: a deeper shade in light mode, a lighter one in dark mode.
    static let accentText = Color(nsColor: NSColor(name: "accentText") { appearance in
        let accent = NSColor.controlAccentColor
        return appearance.isDark
            ? accent.blended(withFraction: 0.3, of: .white) ?? accent
            : accent.blended(withFraction: 0.25, of: .black) ?? accent
    })

    static let warning = Color(nsColor: StatusColors.clientError)

    static func status(_ code: Int) -> Color {
        Color(nsColor: StatusColors.color(for: code))
    }
}

/// HTTP status classes. Every use pairs the color with the status text.
enum StatusColors {
    static let success = NSColor(light: 0x1A7F37, dark: 0x4AD66D, highContrastLight: 0x12602A, highContrastDark: 0x7EE896)
    static let redirect = NSColor(light: 0x0A5FC2, dark: 0x64A8FF, highContrastLight: 0x0848A0, highContrastDark: 0x99C7FF)
    static let clientError = NSColor(light: 0xA35200, dark: 0xFFB340, highContrastLight: 0x7F4000, highContrastDark: 0xFFCC80)
    static let serverError = NSColor(light: 0xC4261D, dark: 0xFF6961, highContrastLight: 0x9C1C15, highContrastDark: 0xFF9A94)

    static func color(for code: Int) -> NSColor {
        switch code {
        case 200..<300:
            return success
        case 300..<400:
            return redirect
        case 400..<500:
            return clientError
        default:
            return serverError
        }
    }
}

/// Syntax colors for code shown on the text background. Each passes 4.5:1 in both modes.
enum CodeColors {
    static let key = NSColor(light: 0x9B2393, dark: 0xFC5FA3, highContrastLight: 0x7A1B74, highContrastDark: 0xFF8CC0)
    static let string = NSColor(light: 0x1F7A2E, dark: 0x7FD88F, highContrastLight: 0x155E22, highContrastDark: 0xA8EDB3)
    static let number = NSColor(light: 0x1C00CF, dark: 0xD9C97C, highContrastLight: 0x14009C, highContrastDark: 0xEDE0A0)
    static let literal = NSColor(light: 0xA14A00, dark: 0xFFA05A, highContrastLight: 0x7F3A00, highContrastDark: 0xFFC08F)
    static let headerName = NSColor(light: 0x0F5FA0, dark: 0x6BC7FF, highContrastLight: 0x0A4778, highContrastDark: 0x9ED9FF)
}

extension NSColor {
    convenience init(light: UInt32, dark: UInt32, highContrastLight: UInt32? = nil, highContrastDark: UInt32? = nil) {
        self.init(name: nil) { appearance in
            switch appearance.bestMatch(from: [.aqua, .darkAqua, .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua]) {
            case .darkAqua:
                return NSColor(hex: dark)
            case .accessibilityHighContrastAqua:
                return NSColor(hex: highContrastLight ?? light)
            case .accessibilityHighContrastDarkAqua:
                return NSColor(hex: highContrastDark ?? dark)
            default:
                return NSColor(hex: light)
            }
        }
    }

    convenience init(hex: UInt32) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }

    /// WCAG relative luminance, 0 for black and 1 for white.
    var relativeLuminance: CGFloat {
        guard let rgb = usingColorSpace(.sRGB) else {
            return 0
        }
        func channel(_ value: CGFloat) -> CGFloat {
            value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(rgb.redComponent) + 0.7152 * channel(rgb.greenComponent) + 0.0722 * channel(rgb.blueComponent)
    }
}

extension NSAppearance {
    var isDark: Bool {
        bestMatch(from: [.aqua, .darkAqua, .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua])
            .map { $0 == .darkAqua || $0 == .accessibilityHighContrastDarkAqua } ?? false
    }
}
