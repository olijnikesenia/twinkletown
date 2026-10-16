import SwiftUI

enum Companion: String, Codable, CaseIterable, Identifiable {
    case bibi, mimi, coco, lolo

    var id: String { rawValue }

    var name: String {
        switch self {
        case .bibi: "Bibi the Bunny"
        case .mimi: "Mimi the Cat"
        case .coco: "Coco the Bear"
        case .lolo: "Lolo the Fox"
        }
    }

    var shortName: String {
        switch self {
        case .bibi: "Bibi"
        case .mimi: "Mimi"
        case .coco: "Coco"
        case .lolo: "Lolo"
        }
    }

    var blurb: String {
        switch self {
        case .bibi: "Cheerful and bouncy! Loves shiny stars."
        case .mimi: "Playful and sparkly! Loves pink diamonds."
        case .coco: "Friendly and cozy! Gives the best hugs."
        case .lolo: "Brave explorer! Always finds the way."
        }
    }

    var fur: Color {
        switch self {
        case .bibi: Color(hex: 0xFDFDFF)
        case .mimi: Color(hex: 0xFFC3E6)
        case .coco: Color(hex: 0xF2B65A)
        case .lolo: Color(hex: 0xFF9A45)
        }
    }

    var furShade: Color {
        switch self {
        case .bibi: Color(hex: 0xD9E6FF)
        case .mimi: Color(hex: 0xF29BCB)
        case .coco: Color(hex: 0xD38F35)
        case .lolo: Color(hex: 0xE5762A)
        }
    }

    var accent: Color {
        switch self {
        case .bibi: Palette.royal
        case .mimi: Palette.hotPink
        case .coco: Palette.royal
        case .lolo: Color(hex: 0xFFF3E4)
        }
    }

    /// Card / selection color.
    var theme: Color {
        switch self {
        case .bibi: Palette.sky
        case .mimi: Palette.pink
        case .coco: Palette.yellow
        case .lolo: Color(hex: 0xFFD3A8)
        }
    }
}
