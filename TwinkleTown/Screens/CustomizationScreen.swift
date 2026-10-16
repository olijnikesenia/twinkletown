import SwiftUI

// MARK: - Screen 11: Character customization

struct CustomizationScreen: View {
    enum Tab: Hashable { case friend, slot(EquipSlot) }

    @Environment(GameState.self) private var state
    @Environment(Router.self) private var router
    @State private var tab: Tab = .slot(.outfit)
    /// An item that is being tried on but not owned yet.
    @State private var preview: ShopItem?
    @State private var buying: ShopItem?
    @State private var saved = false

    private let tabs: [Tab] = [.friend] + EquipSlot.allCases.map { .slot($0) }

    private var shownAppearance: Appearance {
        var a = state.data.appearance
        if let preview, let slot = preview.slot { a.slots[slot] = preview.id }
        return a
    }

    var body: some View {
        ZStack {
            MagicBackground(colors: [Palette.violet, Palette.lilac, Palette.lavender])
            VStack(spacing: 6) {
                ScreenHeader(title: "Dress Up", onBack: router.back)
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 20) {
                        stage.frame(width: 420)
                        VStack { picker }.frame(width: 440)
                    }
                    .frame(minWidth: 900)
                    VStack(spacing: 6) { stage; picker }
                }
            }
            if let item = buying {
                ConfirmDialog(title: "Buy \(item.name)?", message: "It costs \(item.price) stars.", confirmTitle: "Buy!",
                              confirmColor: Palette.green,
                              onConfirm: {
                                  if state.buy(item.id) == .success {
                                      state.equip(item.id)
                                      feedback(.purchase, haptic: .medium)
                                      preview = nil
                                  }
                                  buying = nil
                              },
                              onCancel: { buying = nil })
            }
        }
        .onDisappear { preview = nil }
    }

    private var stage: some View {
        let companion = state.data.companion ?? .bibi
        return VStack(spacing: 8) {
            ZStack {
                BackgroundArt(id: shownAppearance.background)
                IslandView(width: 200, flowers: true).offset(y: 100)
                CompanionView(companion: companion, appearance: shownAppearance, size: Device.isPad ? 220 : 160, happy: saved)
            }
            .frame(height: Device.isPad ? 360 : 270)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white, lineWidth: 4))
            .padding(.horizontal, 16)

            if let preview {
                HStack(spacing: 10) {
                    Text("Trying on \(preview.name)").font(.game(15)).foregroundStyle(.white).lineLimit(1)
                    BigButton(title: "\(preview.price)", icon: .shop, color: state.data.stars >= preview.price ? Palette.hotPink : Color(hex: 0xA9B6CC), height: 44) {
                        if state.data.stars >= preview.price { buying = preview } else { feedback(.gentleOops) }
                    }
                    .fixedSize()
                    RoundIconButton(icon: .close, color: Palette.lilac, size: 44, label: "Stop trying on") { self.preview = nil }
                }
                .padding(.horizontal, 16)
            } else {
                BigButton(title: saved ? "Saved!" : "Save my look", icon: .check, color: saved ? Palette.green : Palette.royal, height: 48) {
                    state.saveNow()
                    feedback(.reward)
                    saved = true
                    Task { try? await Task.sleep(for: .seconds(1.5)); saved = false }
                }
                .padding(.horizontal, 40)
            }
        }
    }

    private var picker: some View {
        VStack(spacing: 4) {
            CategoryTabs(items: tabs, selection: $tab) { t in
                switch t {
                case .friend: "Friend"
                case let .slot(s): s.title
                }
            }
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 12) {
                    switch tab {
                    case .friend:
                        ForEach(Companion.allCases) { c in
                            tile(selected: state.data.companion == c, locked: false) {
                                CompanionArt(companion: c).frame(width: 200, height: 240).scaleEffect(0.36).frame(width: 72, height: 86)
                            } action: {
                                state.selectCompanion(c)
                            }
                        }
                    case let .slot(slot):
                        if slot != .background {
                            tile(selected: state.data.appearance.item(slot) == nil && preview?.slot != slot, locked: false) {
                                IconView(icon: .close, color: Palette.text.opacity(0.4), size: 40)
                            } action: {
                                state.unequip(slot)
                                if preview?.slot == slot { preview = nil }
                            }
                        }
                        ForEach(Catalog.items(in: slot).filter { !$0.isExclusive || state.owns($0.id) }) { item in
                            let owned = state.owns(item.id)
                            tile(selected: state.isEquipped(item.id) || preview == item, locked: !owned) {
                                ItemArt(item: item).padding(6)
                            } action: {
                                if owned {
                                    state.equip(item.id)
                                    preview = nil
                                } else {
                                    preview = item
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    private func tile<V: View>(selected: Bool, locked: Bool, @ViewBuilder content: () -> V, action: @escaping () -> Void) -> some View {
        Button {
            feedback(.place)
            withAnimation(.spring(response: 0.3)) { action() }
        } label: {
            content()
                .frame(width: 96, height: 96)
                .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.9)))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(selected ? Palette.hotPink : .white, lineWidth: selected ? 5 : 3))
                .overlay(alignment: .bottomTrailing) {
                    if locked {
                        IconView(icon: .lock, color: .white, size: 16).padding(5)
                            .background(Circle().fill(Palette.text.opacity(0.6))).padding(4)
                    }
                }
                .scaleEffect(selected ? 1.05 : 1)
        }
        .buttonStyle(.plain)
    }
}
