import SwiftUI

// MARK: - Screen 10: Twinkle Shop

struct ShopScreen: View {
    @Environment(GameState.self) private var state
    @Environment(Router.self) private var router
    @State private var category: ItemCategory = .outfit
    @State private var confirming: ShopItem?
    @State private var outcome: (item: ShopItem, result: PurchaseResult)?

    private var items: [ShopItem] { Catalog.items.filter { $0.category == category && $0.inShop } }

    var body: some View {
        ZStack {
            MagicBackground(colors: [Palette.violet, Palette.pink, Palette.lavender])
            VStack(spacing: 4) {
                ScreenHeader(title: "Twinkle Shop", onBack: router.back)
                Text("Spend stars you earn by playing. Everything here is free!")
                    .font(.game(14, .semibold)).foregroundStyle(.white).padding(.horizontal, 16)
                CategoryTabs(items: ItemCategory.allCases, selection: $category) { $0.title }
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: Device.isPad ? 190 : 150), spacing: 14)], spacing: 14) {
                        ForEach(items) { item in
                            ShopItemCard(item: item) { action(for: item) }
                        }
                    }
                    .padding(16)
                }
            }
            if let item = confirming {
                ConfirmDialog(title: "Buy \(item.name)?", message: "It costs \(item.price) stars. You have \(state.data.stars).",
                              confirmTitle: "Buy!", confirmColor: Palette.green,
                              onConfirm: { purchase(item) }, onCancel: { confirming = nil })
            }
            if let outcome { outcomePopup(outcome.item, outcome.result) }
        }
    }

    private func action(for item: ShopItem) {
        if state.owns(item.id) {
            if item.slot != nil {
                if state.isEquipped(item.id), item.slot != .background { state.unequip(item.slot!) } else { state.equip(item.id) }
                feedback(.place)
            } else {
                router.go(.garden)
            }
        } else if state.data.stars < item.price {
            outcome = (item, .notEnoughStars(missing: item.price - state.data.stars))
            feedback(.gentleOops)
        } else {
            confirming = item
        }
    }

    private func purchase(_ item: ShopItem) {
        confirming = nil
        let result = state.buy(item.id)
        if result == .success { feedback(.purchase, haptic: .medium) }
        outcome = (item, result)
    }

    private func outcomePopup(_ item: ShopItem, _ result: PurchaseResult) -> some View {
        PopupCard {
            VStack(spacing: 14) {
                ItemArt(item: item).frame(width: 110, height: 110)
                switch result {
                case .success:
                    Text("Yay! It's yours!").font(.game(26)).foregroundStyle(Palette.text)
                    if item.slot != nil {
                        BigButton(title: "Wear it now", icon: .wardrobe, color: Palette.hotPink) {
                            state.equip(item.id)
                            outcome = nil
                        }
                    } else {
                        BigButton(title: "Go to Garden", icon: .garden, color: Palette.green) {
                            outcome = nil
                            router.go(.garden)
                        }
                    }
                case let .notEnoughStars(missing):
                    Text("Almost there!").font(.game(26)).foregroundStyle(Palette.text)
                    Text("You need \(missing) more stars. Play some levels to earn them!")
                        .font(.game(17, .semibold)).foregroundStyle(Palette.text.opacity(0.8)).multilineTextAlignment(.center)
                case .alreadyOwned:
                    Text("You already have this!").font(.game(22)).foregroundStyle(Palette.text)
                case .unavailable:
                    Text("This item can't be bought.").font(.game(22)).foregroundStyle(Palette.text)
                }
                BigButton(title: "OK", color: Palette.royal) { outcome = nil }
            }
        }
    }
}

struct ShopItemCard: View {
    let item: ShopItem
    let onTap: () -> Void
    @Environment(GameState.self) private var state

    var body: some View {
        let owned = state.owns(item.id)
        let equipped = state.isEquipped(item.id)
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 18).fill(Palette.crystal.opacity(0.55))
                ItemArt(item: item).padding(10)
            }
            .frame(height: 110)
            .overlay(alignment: .topTrailing) {
                if equipped {
                    IconView(icon: .check, color: .white, size: 18).padding(6)
                        .background(Circle().fill(Palette.green)).offset(x: 6, y: -6)
                }
            }
            Text(item.name).font(.game(15)).foregroundStyle(Palette.text).lineLimit(2).multilineTextAlignment(.center)
                .frame(height: 38)
            Button { feedback(); onTap() } label: {
                HStack(spacing: 4) {
                    if owned {
                        Text(item.slot == nil ? "Place" : equipped ? (item.slot == .background ? "In use" : "Take off") : "Use")
                    } else {
                        StarCoin(size: 22, face: false)
                        Text("\(item.price)")
                    }
                }
                .font(.game(16))
                .frame(maxWidth: .infinity).frame(height: 40)
            }
            .buttonStyle(CandyButtonStyle(color: owned ? (equipped ? Palette.lilac : Palette.green)
                                          : (state.data.stars >= item.price ? Palette.hotPink : Color(hex: 0xA9B6CC))))
            .accessibilityLabel(owned ? "\(item.name), owned" : "Buy \(item.name) for \(item.price) stars")
        }
        .padding(10)
        .gamePanel()
    }
}
