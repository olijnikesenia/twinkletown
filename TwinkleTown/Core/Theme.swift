import SwiftUI
import UIKit

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}

enum Palette {
    static let royal = Color(hex: 0x327CFF)
    static let deep = Color(hex: 0x1747B8)
    static let sky = Color(hex: 0x8BD9FF)
    static let crystal = Color(hex: 0xB1F5FF)
    static let pink = Color(hex: 0xFFC3E6)
    static let yellow = Color(hex: 0xFFE68A)
    static let mint = Color(hex: 0xA4F2D0)
    static let text = Color(hex: 0x25406C)
    static let hotPink = Color(hex: 0xFF7EB9)
    static let orange = Color(hex: 0xFFA552)
    static let lilac = Color(hex: 0xB9A2FF)
    static let gold = Color(hex: 0xFFC93D)
    static let grape = Color(hex: 0x3A1C9E)
    static let violet = Color(hex: 0x6B3FE0)
    static let lavender = Color(hex: 0xDCCBFF)
    static let green = Color(hex: 0x5FD39A)
    static let rainbow: [Color] = [Color(hex: 0xFF8FB8), Color(hex: 0xFFB86B), Color(hex: 0xFFE27A),
                                   Color(hex: 0x8EEBB8), Color(hex: 0x7CCBFF), Color(hex: 0xB89BFF)]

    /// The five puzzle diamond colors (index = color id used by the engines).
    static let gems: [Color] = [Color(hex: 0x3E8BFF), Color(hex: 0xFF77B7), Color(hex: 0xFFCC33),
                                Color(hex: 0x3FD69A), Color(hex: 0xA77BFF)]
    static let gemNames = ["Blue", "Pink", "Yellow", "Green", "Purple"]
}

extension Font {
    static func game(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

enum Device {
    static var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
}

extension EnvironmentValues {
    /// Combined system + in-game reduced motion preference.
    @Entry var gameReduceMotion: Bool = false
}
