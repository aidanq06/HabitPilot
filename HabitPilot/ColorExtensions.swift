import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 122, 255) // Default to system blue
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
    
    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb = Int(r * 255) << 16 | Int(g * 255) << 8 | Int(b * 255) << 0
        
        return String(format: "#%06x", rgb)
    }
    
    // MARK: - Dark Mode Adaptive Colors
    
    // Adaptive color that changes based on appearance
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
    
    // Adaptive hex colors for better dark mode support
    static func adaptiveHex(light: String, dark: String) -> Color {
        adaptive(light: Color(hex: light), dark: Color(hex: dark))
    }
    
    // Enhanced color palette with dark mode variants
    static let modernPalette: [Color] = [
        Color.adaptiveHex(light: "#007AFF", dark: "#0A84FF"), // iOS Blue
        Color.adaptiveHex(light: "#34C759", dark: "#30D158"), // iOS Green
        Color.adaptiveHex(light: "#FF9500", dark: "#FF9F0A"), // iOS Orange
        Color.adaptiveHex(light: "#FF2D92", dark: "#FF375F"), // iOS Pink
        Color.adaptiveHex(light: "#AF52DE", dark: "#BF5AF2"), // iOS Purple
        Color.adaptiveHex(light: "#5AC8FA", dark: "#64D2FF"), // iOS Light Blue
        Color.adaptiveHex(light: "#FF3B30", dark: "#FF453A"), // iOS Red
        Color.adaptiveHex(light: "#5856D6", dark: "#5E5CE6"), // iOS Indigo
        Color.adaptiveHex(light: "#FFCC02", dark: "#FFD60A"), // iOS Yellow
        Color.adaptiveHex(light: "#30D158", dark: "#32D74B"), // iOS Mint
        Color.adaptiveHex(light: "#64D2FF", dark: "#70D7FF"), // iOS Cyan
        Color.adaptiveHex(light: "#FF6B35", dark: "#FF6B35")  // iOS Deep Orange
    ]
    
    // Semantic colors with dark mode variants
    static let successGreen = Color.adaptiveHex(light: "#34C759", dark: "#30D158")
    static let warningOrange = Color.adaptiveHex(light: "#FF9500", dark: "#FF9F0A")
    static let errorRed = Color.adaptiveHex(light: "#FF3B30", dark: "#FF453A")
    static let infoBlue = Color.adaptiveHex(light: "#007AFF", dark: "#0A84FF")
    static let primaryBlue = Color.adaptiveHex(light: "#007AFF", dark: "#0A84FF")
    
    // Background colors (already adaptive with system colors)
    static let primaryBackground = Color(.systemBackground)
    static let cardBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    
    // Text colors (already adaptive with system colors)
    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText = Color(.tertiaryLabel)
    
    // MARK: - Dark Mode Specific Colors
    
    // Dark mode optimized shadows
    static let cardShadow = Color.adaptive(
        light: Color.black.opacity(0.08),
        dark: Color.black.opacity(0.3)
    )
    
    static let mediumShadow = Color.adaptive(
        light: Color.black.opacity(0.12),
        dark: Color.black.opacity(0.4)
    )
    
    static let strongShadow = Color.adaptive(
        light: Color.black.opacity(0.16),
        dark: Color.black.opacity(0.5)
    )
    
    // Dark mode optimized glass effect
    static let glassGradient = LinearGradient(
        colors: [
            Color.adaptive(
                light: Color.white.opacity(0.25),
                dark: Color.white.opacity(0.1)
            ),
            Color.adaptive(
                light: Color.white.opacity(0.1),
                dark: Color.white.opacity(0.05)
            )
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Check if color is dark for better contrast
    var isDarkColor: Bool {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        // Perceived brightness formula
        let brightness = (r * 299 + g * 587 + b * 114) / 1000
        return brightness < 0.5
    }
    
    // Get contrasting text color
    var contrastingTextColor: Color {
        return isDarkColor ? .white : .black
    }
    
    // Get a lighter version of the color
    func lighter(by percentage: CGFloat = 0.3) -> Color {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return Color(
            .sRGB,
            red: min(r + percentage, 1.0),
            green: min(g + percentage, 1.0),
            blue: min(b + percentage, 1.0),
            opacity: a
        )
    }
    
    // Get a darker version of the color
    func darker(by percentage: CGFloat = 0.3) -> Color {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return Color(
            .sRGB,
            red: max(r - percentage, 0.0),
            green: max(g - percentage, 0.0),
            blue: max(b - percentage, 0.0),
            opacity: a
        )
    }
    
    // MARK: - Gradient Extensions
    
    // Create a subtle gradient from this color
    func subtleGradient() -> LinearGradient {
        LinearGradient(
            colors: [
                self.opacity(0.8),
                self.opacity(0.6),
                self.opacity(0.4)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Create a vibrant gradient from this color
    func vibrantGradient() -> LinearGradient {
        LinearGradient(
            colors: [
                self,
                self.lighter(by: 0.2),
                self.lighter(by: 0.4)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Create a radial gradient from this color
    func radialGradient() -> RadialGradient {
        RadialGradient(
            colors: [
                self.opacity(0.8),
                self.opacity(0.4),
                self.opacity(0.1)
            ],
            center: .center,
            startRadius: 0,
            endRadius: 100
        )
    }
    
    // MARK: - Modern UI Gradients (Dark Mode Optimized)
    
    // Background gradients for different contexts
    static let primaryGradient = LinearGradient(
        colors: [
            Color.adaptiveHex(light: "#667eea", dark: "#7B68EE"),
            Color.adaptiveHex(light: "#764ba2", dark: "#9370DB")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [
            Color.successGreen,
            Color.successGreen.lighter(by: 0.3)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warningGradient = LinearGradient(
        colors: [
            Color.warningOrange,
            Color.warningOrange.lighter(by: 0.3)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let infoGradient = LinearGradient(
        colors: [
            Color.infoBlue,
            Color.infoBlue.lighter(by: 0.3)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Card background gradients
    static let cardGradient = LinearGradient(
        colors: [
            Color.cardBackground,
            Color.cardBackground.opacity(0.95)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Animation Colors (Dark Mode Optimized)
    
    // Colors for confetti animation
    static let confettiColors: [Color] = [
        Color.adaptiveHex(light: "#FF6B6B", dark: "#FF7B7B"),
        Color.adaptiveHex(light: "#4ECDC4", dark: "#5EDDD4"),
        Color.adaptiveHex(light: "#45B7D1", dark: "#55C7E1"),
        Color.adaptiveHex(light: "#96CEB4", dark: "#A6DEC4"),
        Color.adaptiveHex(light: "#FFEAA7", dark: "#FFFAB7"),
        Color.adaptiveHex(light: "#DDA0DD", dark: "#EDB0ED"),
        Color.adaptiveHex(light: "#98D8C8", dark: "#A8E8D8"),
        Color.adaptiveHex(light: "#F7DC6F", dark: "#FFEC7F")
    ]
    
    // Progress bar colors
    static let progressGradient = LinearGradient(
        colors: [
            Color.successGreen,
            Color.successGreen.lighter(by: 0.4)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Colored shadows
    func shadowColor(opacity: Double = 0.3) -> Color {
        self.opacity(opacity)
    }
} 