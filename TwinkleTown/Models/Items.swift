import Foundation

enum ItemCategory: String, Codable, CaseIterable, Identifiable {
    case outfit, accessory, decoration, background
    var id: String { rawValue }
    var title: String {
        switch self {
        case .outfit: "Outfits"
        case .accessory: "Accessories"
        case .decoration: "Garden"
        case .background: "Skies"
        }
    }
}

/// Where an item is worn / used.
enum EquipSlot: String, Codable, CaseIterable, Identifiable {
    case outfit, hat, glasses, wings, bow, effect, background
    var id: String { rawValue }
    var title: String {
        switch self {
        case .outfit: "Outfit"
        case .hat: "Hat"
        case .glasses: "Glasses"
        case .wings: "Wings"
        case .bow: "Bow"
        case .effect: "Magic"
        case .background: "Sky"
        }
    }
}

struct ShopItem: Identifiable, Hashable {
    let id: String
    let name: String
    let price: Int
    let category: ItemCategory
    let slot: EquipSlot?
    /// Starter items are owned from the beginning and not sold.
    var isStarter = false
    /// Exclusive items cannot be bought (777 reward).
    var isExclusive = false

    var inShop: Bool { !isStarter && !isExclusive }
}

enum Catalog {
    static let defaultBackground = "bg_night_city"
    static let celebrationReward = "outfit_starlight_cape"

    static let items: [ShopItem] = [
        // Outfits
        ShopItem(id: "outfit_rainbow_hoodie", name: "Rainbow Hoodie", price: 25, category: .outfit, slot: .outfit),
        ShopItem(id: "outfit_blue_wizard", name: "Blue Wizard Costume", price: 60, category: .outfit, slot: .outfit),
        ShopItem(id: "outfit_crystal_explorer", name: "Crystal Explorer", price: 45, category: .outfit, slot: .outfit),
        ShopItem(id: "outfit_star_pajamas", name: "Star Pajamas", price: 35, category: .outfit, slot: .outfit),
        ShopItem(id: "outfit_cloud", name: "Cloud Costume", price: 50, category: .outfit, slot: .outfit),
        ShopItem(id: "outfit_flower", name: "Flower Outfit", price: 40, category: .outfit, slot: .outfit),
        ShopItem(id: celebrationReward, name: "Starlight Cape", price: 0, category: .outfit, slot: .outfit, isExclusive: true),
        // Accessories
        ShopItem(id: "hat_diamond_crown", name: "Diamond Crown", price: 90, category: .accessory, slot: .hat),
        ShopItem(id: "hat_rainbow", name: "Rainbow Hat", price: 30, category: .accessory, slot: .hat),
        ShopItem(id: "glasses_star", name: "Star Glasses", price: 25, category: .accessory, slot: .glasses),
        ShopItem(id: "hat_bunny_ears", name: "Bunny Ears", price: 30, category: .accessory, slot: .hat),
        ShopItem(id: "wings_crystal", name: "Crystal Wings", price: 80, category: .accessory, slot: .wings),
        ShopItem(id: "bow_magical", name: "Magical Bow", price: 20, category: .accessory, slot: .bow),
        ShopItem(id: "effect_sparkles", name: "Sparkle Aura", price: 0, category: .accessory, slot: .effect, isStarter: true),
        ShopItem(id: "effect_hearts", name: "Heart Bubbles", price: 40, category: .accessory, slot: .effect),
        // Garden decorations
        ShopItem(id: "deco_crystal_fountain", name: "Crystal Fountain", price: 55, category: .decoration, slot: nil),
        ShopItem(id: "deco_rainbow_tree", name: "Rainbow Tree", price: 40, category: .decoration, slot: nil),
        ShopItem(id: "deco_mushroom_house", name: "Blue Mushroom House", price: 70, category: .decoration, slot: nil),
        ShopItem(id: "deco_diamond_bench", name: "Diamond Bench", price: 30, category: .decoration, slot: nil),
        ShopItem(id: "deco_star_lantern", name: "Star Lantern", price: 25, category: .decoration, slot: nil),
        ShopItem(id: "deco_flower_arch", name: "Flower Arch", price: 45, category: .decoration, slot: nil),
        ShopItem(id: "deco_sparkling_pond", name: "Sparkling Pond", price: 50, category: .decoration, slot: nil),
        ShopItem(id: "deco_crystal_tree", name: "Crystal Tree", price: 0, category: .decoration, slot: nil, isStarter: true),
        ShopItem(id: "deco_pink_flowers", name: "Pink Flowers", price: 0, category: .decoration, slot: nil, isStarter: true),
        ShopItem(id: "deco_crystal_cluster", name: "Crystal Cluster", price: 0, category: .decoration, slot: nil, isStarter: true),
        ShopItem(id: "deco_cloud_puff", name: "Cloud Puff", price: 0, category: .decoration, slot: nil, isStarter: true),
        ShopItem(id: "deco_sunflower", name: "Sunny Flower", price: 0, category: .decoration, slot: nil, isStarter: true),
        ShopItem(id: "deco_toadstool", name: "Spotty Mushroom", price: 0, category: .decoration, slot: nil, isStarter: true),
        // Backgrounds
        ShopItem(id: defaultBackground, name: "Night City", price: 0, category: .background, slot: .background, isStarter: true),
        ShopItem(id: "bg_twinkle_sky", name: "Twinkle Sky", price: 0, category: .background, slot: .background, isStarter: true),
        ShopItem(id: "bg_crystal_sky", name: "Crystal Sky", price: 35, category: .background, slot: .background),
        ShopItem(id: "bg_rainbow_clouds", name: "Rainbow Clouds", price: 45, category: .background, slot: .background),
        ShopItem(id: "bg_magical_night", name: "Magical Night", price: 55, category: .background, slot: .background),
        ShopItem(id: "bg_sparkling_forest", name: "Sparkling Forest", price: 50, category: .background, slot: .background),
        ShopItem(id: "bg_pastel_dreamland", name: "Pastel Dreamland", price: 60, category: .background, slot: .background),
    ]

    static let byID: [String: ShopItem] = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
    static func item(_ id: String) -> ShopItem? { byID[id] }
    static var starterIDs: Set<String> { Set(items.filter(\.isStarter).map(\.id)) }
    static func items(in slot: EquipSlot) -> [ShopItem] { items.filter { $0.slot == slot } }
}
