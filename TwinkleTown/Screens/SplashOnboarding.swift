import SwiftUI

struct TwinkleLogo: View {
    var size: CGFloat = 52

    var body: some View {
        VStack(spacing: -size * 0.2) {
            letters("Twinkle", colors: [Palette.yellow, .white, Palette.pink, .white, Palette.mint, .white, Palette.yellow])
            letters("Town", colors: [Palette.crystal, .white, Palette.pink, Palette.yellow])
        }
        .overlay(alignment: .topTrailing) {
            SparkleShape().fill(.white).frame(width: size * 0.5, height: size * 0.5)
                .shadow(color: Palette.yellow, radius: 6).offset(x: size * 0.3, y: -size * 0.15)
        }
        .accessibilityElement()
        .accessibilityLabel("Twinkle Town")
    }

    private func letters(_ word: String, colors: [Color]) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(word.enumerated()), id: \.offset) { i, ch in
                Text(String(ch))
                    .font(.game(size, .black))
                    .foregroundStyle(colors[i % colors.count])
                    .shadow(color: Palette.deep, radius: 0, x: 0, y: size * 0.07)
                    .shadow(color: Palette.deep, radius: 0, x: size * 0.03, y: 0)
                    .shadow(color: Palette.deep, radius: 0, x: -size * 0.03, y: 0)
                    .rotationEffect(.degrees(i.isMultiple(of: 2) ? -5 : 5))
            }
        }
    }
}

struct FloatingModifier: ViewModifier {
    var amount: CGFloat = 10
    var duration: Double = 1.6
    @State private var up = false
    @Environment(\.gameReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .offset(y: up ? -amount : amount)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: duration).repeatForever()) { up = true }
            }
    }
}

extension View {
    func floating(_ amount: CGFloat = 10, duration: Double = 1.6) -> some View {
        modifier(FloatingModifier(amount: amount, duration: duration))
    }
}

// MARK: - Screen 1: Splash

struct SplashScreen: View {
    let onFinish: () -> Void
    @State private var appear = false
    @State private var progress = 0.0

    var body: some View {
        ZStack {
            MagicBackground()
            VStack(spacing: 18) {
                Spacer()
                ZStack {
                    Circle().fill(Palette.crystal.opacity(0.5)).frame(width: 160).blur(radius: 20)
                    DiamondIcon(size: 110)
                }
                .floating(12)
                TwinkleLogo(size: Device.isPad ? 80 : 56)
                    .scaleEffect(appear ? 1 : 0.4)
                CompanionView(companion: .bibi, size: 130, happy: true)
                Spacer()
                VStack(spacing: 8) {
                    GameProgressBar(value: progress, colors: [Palette.pink, Palette.yellow, Palette.mint]).frame(width: 220)
                    Text("Polishing diamonds...").font(.game(16, .bold)).foregroundStyle(.white)
                }
                .padding(.bottom, 40)
            }
            .opacity(appear ? 1 : 0)
        }
        .task {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) { appear = true }
            withAnimation(.easeInOut(duration: 1.8)) { progress = 1 }
            AudioManager.shared.startMusic()
            try? await Task.sleep(for: .seconds(2.2))
            withAnimation(.easeInOut(duration: 0.4)) { onFinish() }
        }
    }
}

// MARK: - Screen 2: Onboarding

struct OnboardingScreen: View {
    let onDone: () -> Void
    @State private var page = 0

    private struct Card {
        let title: String
        let text: String
        let art: AnyView
    }

    private var cards: [Card] {
        [
            Card(title: "Welcome to Twinkle Town!", text: "Our magical town has lost its sparkle. Will you help us?",
                 art: AnyView(ZStack { IslandView(width: 240).offset(y: 50); CompanionView(companion: .bibi, size: 120).offset(y: -20) })),
            Card(title: "Diamonds bring back the sparkle", text: "Every diamond you find makes the town shine again.",
                 art: AnyView(HStack(spacing: 4) { ForEach(0..<3) { i in GemView(color: Palette.gems[i == 1 ? 0 : i + 2], size: i == 1 ? 110 : 70).floating(CGFloat(6 + i * 3)) } })),
            Card(title: "Play happy games", text: "Match diamonds, sort crystals and find pairs to earn diamonds and stars.",
                 art: AnyView(HStack(spacing: 16) { GemView(color: Palette.gems[1], shape: .heart, size: 70); StarCoin(size: 80); GemView(color: Palette.gems[3], shape: .round, size: 70) })),
            Card(title: "Stars buy pretty things", text: "Dress up your friend and decorate your very own garden.",
                 art: AnyView(CompanionView(companion: .mimi, appearance: Appearance(slots: [.hat: "hat_diamond_crown", .outfit: "outfit_rainbow_hoodie"]), size: 140))),
            Card(title: "Collect 777 diamonds!", text: "Find all 777 magical diamonds to fully restore Twinkle Town.",
                 art: AnyView(VStack { Text("777").font(.game(90, .black)).foregroundStyle(LinearGradient(colors: [Palette.yellow, .white, Palette.sky], startPoint: .top, endPoint: .bottom)).shadow(color: Palette.deep, radius: 0, y: 5); DiamondIcon(size: 60) })),
        ]
    }

    var body: some View {
        ZStack {
            MagicBackground()
            VStack(spacing: 12) {
                HStack {
                    Spacer()
                    Button("Skip") { feedback(); onDone() }
                        .font(.game(18)).foregroundStyle(.white)
                        .padding(.horizontal, 18).padding(.vertical, 8)
                        .background(Capsule().fill(.white.opacity(0.25)))
                }
                .padding(.horizontal, 20)

                TabView(selection: $page) {
                    ForEach(cards.indices, id: \.self) { i in
                        VStack(spacing: 22) {
                            cards[i].art.frame(height: 220)
                            Text(cards[i].title).font(.game(Device.isPad ? 34 : 26)).foregroundStyle(Palette.text).multilineTextAlignment(.center)
                            Text(cards[i].text).font(.game(Device.isPad ? 22 : 18, .semibold)).foregroundStyle(Palette.text.opacity(0.75)).multilineTextAlignment(.center)
                        }
                        .padding(26)
                        .frame(maxWidth: 520)
                        .gamePanel()
                        .padding(.horizontal, 22)
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(cards.indices, id: \.self) { i in
                        Capsule().fill(i == page ? .white : .white.opacity(0.4)).frame(width: i == page ? 26 : 10, height: 10)
                    }
                }
                .animation(.spring, value: page)

                HStack(alignment: .bottom) {
                    CompanionView(companion: .coco, size: 80, happy: page == cards.count - 1)
                    BigButton(title: page == cards.count - 1 ? "Start Adventure" : "Next", icon: .play,
                              color: page == cards.count - 1 ? Palette.hotPink : Palette.royal, height: 64) {
                        if page == cards.count - 1 { onDone() } else { withAnimation { page += 1 } }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
    }
}
