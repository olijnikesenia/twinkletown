import Foundation

enum PurchaseResult: Equatable {
    case success, alreadyOwned, notEnoughStars(missing: Int), unavailable
}

// MARK: - Shop

extension GameState {
    func owns(_ id: String) -> Bool { data.owned.contains(id) }

    @discardableResult
    func buy(_ id: String) -> PurchaseResult {
        guard let item = Catalog.item(id), item.inShop else { return .unavailable }
        guard !owns(id) else { return .alreadyOwned }
        guard spendStars(item.price) else { return .notEnoughStars(missing: item.price - data.stars) }
        data.owned.insert(id)
        data.stats.purchases += 1
        checkAchievements()
        return .success
    }
}

// MARK: - Customization

extension GameState {
    func selectCompanion(_ companion: Companion) {
        data.companion = companion
    }

    func isEquipped(_ id: String) -> Bool {
        guard let slot = Catalog.item(id)?.slot else { return false }
        if slot == .background { return data.appearance.background == id }
        return data.appearance.item(slot) == id
    }

    @discardableResult
    func equip(_ id: String) -> Bool {
        guard owns(id), let slot = Catalog.item(id)?.slot else { return false }
        data.appearance.slots[slot] = id
        return true
    }

    func unequip(_ slot: EquipSlot) {
        data.appearance.slots[slot] = nil
    }
}

// MARK: - Garden

extension GameState {
    static let gardenLimit = 40

    var ownedDecorations: [ShopItem] {
        Catalog.items.filter { $0.category == .decoration && owns($0.id) }
    }

    @discardableResult
    func placeDecoration(_ id: String, x: Double = 0.5, y: Double = 0.6) -> GardenPlacement? {
        guard owns(id), Catalog.item(id)?.category == .decoration, data.garden.count < Self.gardenLimit else { return nil }
        let placement = GardenPlacement(itemID: id, x: clamp(x), y: clamp(y))
        data.garden.append(placement)
        checkAchievements()
        return placement
    }

    func moveDecoration(_ placementID: UUID, x: Double, y: Double) {
        guard let i = data.garden.firstIndex(where: { $0.id == placementID }) else { return }
        data.garden[i].x = clamp(x)
        data.garden[i].y = clamp(y)
    }

    func removeDecoration(_ placementID: UUID) {
        data.garden.removeAll { $0.id == placementID }
    }

    func setGardenBackground(_ id: String) {
        guard owns(id), Catalog.item(id)?.category == .background else { return }
        data.gardenBackground = id
    }

    private func clamp(_ v: Double) -> Double { min(1, max(0, v)) }
}
