import SwiftUI

// MARK: - Font Extensions with cleaner system fonts
extension Font {
    // MARK: - Display / Large Titles
    static let displayLarge = Font.system(size: 57, weight: .ultraLight, design: .default)
    static let displayMedium = Font.system(size: 45, weight: .light, design: .default)
    static let displaySmall = Font.system(size: 36, weight: .light, design: .default)
    
    // MARK: - Headlines (Elegant, clean)
    static let headlineLarge = Font.system(size: 32, weight: .semibold, design: .default)
    static let headlineMedium = Font.system(size: 28, weight: .semibold, design: .default)
    static let headlineSmall = Font.system(size: 24, weight: .semibold, design: .default)
    
    // MARK: - Titles
    static let titleLarge = Font.system(size: 22, weight: .medium, design: .default)
    static let titleMedium = Font.system(size: 18, weight: .medium, design: .default)
    static let titleSmall = Font.system(size: 14, weight: .semibold, design: .default)
    
    // MARK: - Body (Clean, readable)
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)
    
    // MARK: - Labels
    static let labelLarge = Font.system(size: 15, weight: .medium, design: .default)
    static let labelMedium = Font.system(size: 13, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
    
    // MARK: - Legacy Support
    static var appLargeTitle: Font { .displayLarge }
    static var appTitle1: Font { .headlineLarge }
    static var appTitle2: Font { .headlineMedium }
    static var appTitle3: Font { .headlineSmall }
    static var appHeadline: Font { .titleMedium }
    static var appBody: Font { .bodyLarge }
    static var appBodyBold: Font { .system(size: 17, weight: .semibold, design: .default) }
    static var appCallout: Font { .bodyMedium }
    static var appSubheadline: Font { .bodyMedium }
    static var appFootnote: Font { .bodySmall }
    static var appCaption1: Font { .labelMedium }
    static var appCaption2: Font { .labelSmall }
    static var appLight: Font { .system(size: 17, weight: .light, design: .default) }
    static var appMedium: Font { .system(size: 17, weight: .medium, design: .default) }
    static var appThin: Font { .system(size: 17, weight: .thin, design: .default) }
    static var appButton: Font { .system(size: 16, weight: .semibold, design: .default) }
}

// MARK: - Custom Font Weights
extension Font {
    static func elegant(_ size: CGFloat) -> Font {
        .system(size: size, weight: .light, design: .default)
    }
    
    static func modern(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
    
    static func bold(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }
}

// MARK: - Text Style Modifiers
struct AppTextStyle: ViewModifier {
    enum Style {
        case displayLarge, displayMedium, displaySmall
        case headlineLarge, headlineMedium, headlineSmall
        case titleLarge, titleMedium, titleSmall
        case bodyLarge, bodyMedium, bodySmall
        case labelLarge, labelMedium, labelSmall
    }
    
    let style: Style
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .font(font(for: style))
            .foregroundColor(color)
    }
    
    private func font(for style: Style) -> Font {
        switch style {
        case .displayLarge: return .displayLarge
        case .displayMedium: return .displayMedium
        case .displaySmall: return .displaySmall
        case .headlineLarge: return .headlineLarge
        case .headlineMedium: return .headlineMedium
        case .headlineSmall: return .headlineSmall
        case .titleLarge: return .titleLarge
        case .titleMedium: return .titleMedium
        case .titleSmall: return .titleSmall
        case .bodyLarge: return .bodyLarge
        case .bodyMedium: return .bodyMedium
        case .bodySmall: return .bodySmall
        case .labelLarge: return .labelLarge
        case .labelMedium: return .labelMedium
        case .labelSmall: return .labelSmall
        }
    }
}

extension View {
    func textStyle(_ style: AppTextStyle.Style, color: Color = .textPrimary) -> some View {
        modifier(AppTextStyle(style: style, color: color))
    }
}

// MARK: - Letter Spacing Extension
struct LetterSpacing: ViewModifier {
    let spacing: CGFloat
    
    func body(content: Content) -> some View {
        content
            .kerning(spacing)
    }
}

extension View {
    func letterSpacing(_ spacing: CGFloat) -> some View {
        modifier(LetterSpacing(spacing: spacing))
    }
}
