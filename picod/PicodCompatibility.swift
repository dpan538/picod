import SwiftUI

enum PicodMap {
    static let tileColumns = 28
}

struct MapAmbientMoodCurve: Equatable {
    let progress: Double

    static let neutral = MapAmbientMoodCurve(progress: 0.14)
}

enum PicodFont {
    static let displayLG = Font.custom("AmericanTypewriter", size: 22)
    static let monoSM = Font.custom("Courier", size: 11)
    static let monoBoldSM = Font.custom("Courier-Bold", size: 11)

    static func display(_ size: CGFloat) -> Font {
        .custom("AmericanTypewriter", size: size)
    }

    static func mono(_ size: CGFloat) -> Font {
        .custom("Courier", size: size)
    }

    static func monoBold(_ size: CGFloat) -> Font {
        .custom("Courier-Bold", size: size)
    }
}

enum PicodBorder {
    static let width: CGFloat = 2
    static let petFrame: CGFloat = 6
}

enum PicodKerning {
    static let petLabel: CGFloat = 1.2
}

struct PicodSymbolIcon: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 23, weight: .semibold))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(Color.picod_ink)
            .frame(width: PicodIconGrid.box + 4, height: PicodIconGrid.box + 4)
    }
}

extension Color {
    static let picod_paper = Color(hex: "EDEADE")
    static let picod_paper2 = Color(hex: "E4DDCE")
    static let picod_ink = Color(hex: "1A1814")
    static let picod_ink2 = Color(hex: "665747")
    static let picod_mid = Color(hex: "8A7A68")
    static let picod_tile_a = Color(hex: "CBD7B8")
    static let picod_tile_b = Color(hex: "D7E0C7")

    init(hex: String) {
        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double

        switch cleaned.count {
        case 8:
            red = Double((value >> 24) & 0xFF) / 255.0
            green = Double((value >> 16) & 0xFF) / 255.0
            blue = Double((value >> 8) & 0xFF) / 255.0
            alpha = Double(value & 0xFF) / 255.0
        case 6:
            red = Double((value >> 16) & 0xFF) / 255.0
            green = Double((value >> 8) & 0xFF) / 255.0
            blue = Double(value & 0xFF) / 255.0
            alpha = 1.0
        default:
            red = 0
            green = 0
            blue = 0
            alpha = 1.0
        }

        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
}

extension TestMapFactory {
    static func devMap(context: WorldGenerationContext) -> TestMap {
        reviewWorld(context: context, variant: DevTestMode.mapReviewVariant)
    }
}
