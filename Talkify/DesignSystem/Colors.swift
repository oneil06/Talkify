import SwiftUI

extension Color {
    // MARK: - Primary Brand Colors
    static let brandPrimary = Color(hex: "FF6B35")  // Warm coral orange
    static let brandSecondary = Color(hex: "6366F1") // Indigo
    
    // MARK: - Background Colors
    static let appBackgroundPrimary = Color(hex: "FAFAFA")
    static let appBackgroundSecondary = Color(hex: "F5F5F7")
    static let appBackgroundTertiary = Color(hex: "EEEEEE")
    static let cardBackground = Color.white
    
    // MARK: - Gradient Colors
    static let gradientStart = Color(hex: "F8F9FF")
    static let gradientMid = Color(hex: "F0F4FF")
    static let gradientEnd = Color(hex: "E8F4F8")
    
    static let primaryGradient = LinearGradient(
        colors: [brandPrimary, Color(hex: "FF8C5A")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let secondaryGradient = LinearGradient(
        colors: [brandSecondary, Color(hex: "818CF8")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let softGradient = LinearGradient(
        colors: [gradientStart, gradientMid, gradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let darkOverlay = LinearGradient(
        colors: [.black.opacity(0.6), .black.opacity(0.2)],
        startPoint: .bottom,
        endPoint: .top
    )
    
    // MARK: - Text Colors
    static let textPrimary = Color(hex: "0F0F0F")
    static let textSecondary = Color(hex: "6B7280")
    static let textTertiary = Color(hex: "9CA3AF")
    static let textInverse = Color.white
    
    // MARK: - Accent Colors
    static let accentOrange = Color(hex: "FF6B35")
    static let accentBlue = Color(hex: "6366F1")
    static let accentGreen = Color(hex: "10B981")
    static let accentPink = Color(hex: "EC4899")
    static let accentPurple = Color(hex: "8B5CF6")
    static let accentTeal = Color(hex: "14B8A6")
    
    // MARK: - Semantic Colors
    static let success = Color(hex: "10B981")
    static let warning = Color(hex: "F59E0B")
    static let error = Color(hex: "EF4444")
    static let info = Color(hex: "3B82F6")
    
    // MARK: - Border & Divider
    static let border = Color(hex: "E5E7EB")
    static let divider = Color(hex: "F3F4F6")
    
    // MARK: - Legacy Aliases (for backward compatibility)
    static let appBackground = appBackgroundPrimary
    static let appPrimaryText = textPrimary
    static let appSecondaryText = textSecondary
    static let appTertiaryText = textTertiary
    static let appPrimary = brandPrimary
    static let appSecondary = brandSecondary
    static let appGradientStart = gradientStart
    static let appGradientEnd = gradientEnd
    static let appSuccess = success
    static let appWarning = warning
    static let appError = error
    static let appDivider = divider
    
    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Shadows
extension View {
    func softShadow(color: Color = .black.opacity(0.1), radius: CGFloat = 10, x: CGFloat = 0, y: CGFloat = 4) -> some View {
        self.shadow(color: color, radius: radius, x: x, y: y)
    }
    
    func cardShadow() -> some View {
        self.shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
    }
    
    func floatingShadow() -> some View {
        self.shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 20)
    }
}
