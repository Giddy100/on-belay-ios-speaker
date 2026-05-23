import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    static let appSurface = Color(hex: "#1e100b")
    static let appSurfaceDim = Color(hex: "#1e100b")
    static let appSurfaceBright = Color(hex: "#47352f")
    static let appSurfaceContainerLowest = Color(hex: "#180b07")
    static let appSurfaceContainerLow = Color(hex: "#271813")
    static let appSurfaceContainer = Color(hex: "#2b1c17")
    static let appSurfaceContainerHigh = Color(hex: "#372621")
    static let appSurfaceContainerHighest = Color(hex: "#42312b")
    static let appOnSurface = Color(hex: "#f9dcd4")
    static let appOnSurfaceVariant = Color(hex: "#e3bfb3")
    static let appInverseSurface = Color(hex: "#f9dcd4")
    static let appInverseOnSurface = Color(hex: "#3d2c27")
    static let appOutline = Color(hex: "#aa897f")
    static let appOutlineVariant = Color(hex: "#A6B37D")
    static let appSurfaceTint = Color(hex: "#ffb59c")
    static let appPrimary = Color(hex: "#ffb59c")
    static let appOnPrimary = Color(hex: "#5c1900")
    static let appPrimaryContainer = Color(hex: "#ff5f1f")
    static let appOnPrimaryContainer = Color(hex: "#561700")
    static let appInversePrimary = Color(hex: "#ab3600")
    static let appSecondary = Color(hex: "#bec8cd")
    static let appOnSecondary = Color(hex: "#283236")
    static let appSecondaryContainer = Color(hex: "#414b4f")
    static let appOnSecondaryContainer = Color(hex: "#b0babf")
    static let appTertiary = Color(hex: "#8dcdff")
    static let appOnTertiary = Color(hex: "#00344f")
    static let appTertiaryContainer = Color(hex: "#009de4")
    static let appOnTertiaryContainer = Color(hex: "#00304a")
    static let appError = Color(hex: "#ffb4ab")
    static let appOnError = Color(hex: "#690005")
    static let appErrorContainer = Color(hex: "#93000a")
    static let appOnErrorContainer = Color(hex: "#ffdad6")
    static let appBackground = Color(hex: "#1e100b")
    static let appOnBackground = Color(hex: "#f9dcd4")
    static let appSafetyOrange = Color(hex: "#FF5F1F")
    static let appChalkWhite = Color(hex: "#F4F4F9")
    static let appGraniteGray = Color(hex: "#1A1C1E")
    static let appSlateSurface = Color(hex: "#2D3135")
    static let appActiveGreen = Color(hex: "#39FF14")
    static let appWarningYellow = Color(hex: "#FFD700")
}

extension Font {
    static func appHeadlineLg() -> Font {
        .custom("Lexend-Bold", size: 32)
    }
    static func appHeadlineMd() -> Font {
        .custom("Lexend-SemiBold", size: 24)
    }
    static func appBodyLg() -> Font {
        .custom("Lexend-Regular", size: 18)
    }
    static func appBodySm() -> Font {
        .custom("Lexend-Regular", size: 14)
    }
    static func appLabelCaps() -> Font {
        .custom("JetBrainsMono-Bold", size: 12)
    }
    static func appStatusCode() -> Font {
        .custom("JetBrainsMono-Bold", size: 32)
    }
}

struct AppTheme {
    static let cornerRadiusSm: CGFloat = 4
    static let cornerRadiusDefault: CGFloat = 8
    static let cornerRadiusMd: CGFloat = 12
    static let cornerRadiusLg: CGFloat = 16
    static let cornerRadiusXl: CGFloat = 24
    static let cornerRadiusFull: CGFloat = 9999

    static let unit: CGFloat = 8
    static let marginMobile: CGFloat = 20
    static let gutter: CGFloat = 16
    static let touchTarget: CGFloat = 48
    static let containerPadding: CGFloat = 24
}
