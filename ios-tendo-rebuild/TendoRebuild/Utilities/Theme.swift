import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

/// Tendo Rebuild design tokens. Neutral institutional palette with a single orange accent.
enum Theme {
    static let canvas = Color(hex: 0xF1EFEA)
    static let surface = Color(hex: 0xFAF9F6)
    static let surfaceSunk = Color(hex: 0xE8E5DE)
    static let ink = Color(hex: 0x121212)
    static let inkSecondary = Color(hex: 0x6D6960)
    static let inkTertiary = Color(hex: 0xA39E94)
    static let hairline = Color(hex: 0xDDD9D0)
    static let accent = Color(hex: 0xE5531A)
    static let accentSoft = Color(hex: 0xF6DCCC)
    static let complete = Color(hex: 0x2E7D3A)
    static let completeSoft = Color(hex: 0xDAEAD8)
    static let grid = Color(hex: 0xE3DFD7)

    static let cardRadius: CGFloat = 16
    static let margin: CGFloat = 20
}

extension Font {
    /// Heavy grotesk used for headlines and specimen names.
    static func display(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// Monospaced documentation face used for tracked labels and figures.
    static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

extension Int {
    /// Zero-padded rebuild designation, e.g. 17 -> "017".
    var rebuildCode: String { String(format: "%03d", self) }
}

extension Double {
    var percentString: String { "\(Int((self * 100).rounded(.down)))%" }
    var oneDecimal: String { String(format: "%.1f", self) }
}
