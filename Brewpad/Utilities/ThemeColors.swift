import SwiftUI

struct ThemeColors {
    let background: Color
    let accent: Color
    let textPrimary: Color
    let textSecondary: Color
    let buttonBackground: Color
    let buttonText: Color
    let divider: Color
    let highlight: Color

    static let system = ThemeColors(
        background: Color(uiColor: .systemBackground),
        accent: .blue,
        textPrimary: Color.primary,
        textSecondary: Color.secondary,
        buttonBackground: .blue,
        buttonText: .white,
        divider: Color(UIColor.separator),
        highlight: Color(UIColor.systemFill)
    )

    static let light = system
    static let dark = system

    static let brewpadDark = ThemeColors(
        background: Color(hex: "#2B1A12"),
        accent: Color(hex: "#F5E8DA"),
        textPrimary: Color(hex: "#F5E8DA"),
        textSecondary: Color(hex: "#B49E8A"),
        buttonBackground: Color(hex: "#7A5C48"),
        buttonText: Color(hex: "#FFF7F0"),
        divider: Color(hex: "#3C2A1E"),
        highlight: Color(hex: "#C7A98C")
    )

    static let brewpadLight = ThemeColors(
        background: Color(hex: "#F9F3EE"),
        accent: Color(hex: "#6E3B1E"),
        textPrimary: Color(hex: "#3E2A1B"),
        textSecondary: Color(hex: "#8B6A53"),
        buttonBackground: Color(hex: "#D9B49C"),
        buttonText: Color(hex: "#3E2A1B"),
        divider: Color(hex: "#E4D6CC"),
        highlight: Color(hex: "#A67C5B")
    )
}

extension Color {
    init(hex: String) {
        var hex = hex
        if hex.hasPrefix("#") { hex.removeFirst() }
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1,1,1)
        }
        self.init(red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255)
    }
}
