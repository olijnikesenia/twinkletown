import SwiftUI

func feedback(_ sound: Sound = .tap, haptic: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
    AudioManager.shared.play(sound)
    AudioManager.shared.haptic(haptic)
}

// MARK: - Buttons

/// Glossy, bouncy candy button.
struct CandyButtonStyle: ButtonStyle {
    var color: Color = Palette.royal
    var shape: AnyShape = AnyShape(Capsule())

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background {
                ZStack {
                    shape.fill(color.darker(0.35)).offset(y: configuration.isPressed ? 1 : 5)
                    shape.fill(LinearGradient(colors: [color.lighter(0.25), color], startPoint: .top, endPoint: .bottom))
                    shape.fill(.white.opacity(0.35)).padding(.horizontal, 10).padding(.top, 4)
                        .mask(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center))
                    shape.stroke(.white.opacity(0.7), lineWidth: 2.5)
                }
                .offset(y: configuration.isPressed ? 3 : 0)
            }
            .offset(y: configuration.isPressed ? 3 : 0)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

struct BigButton: View {
    let title: String
    var icon: GameIcon?
    var color: Color = Palette.royal
    var height: CGFloat = 58
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button {
            feedback()
            action()
        } label: {
            HStack(spacing: 10) {
                if let icon { IconView(icon: icon, size: height * 0.4) }
                Text(title).font(.game(height * 0.36)).lineLimit(1).minimumScaleFactor(0.6)
            }
            .shadow(color: color.darker(0.5).opacity(0.5), radius: 0, y: 2)
            .padding(.horizontal, 22)
            .frame(minHeight: height)
        }
        .buttonStyle(CandyButtonStyle(color: enabled ? color : Color(hex: 0xA9B6CC)))
        .disabled(!enabled)
    }
}

struct RoundIconButton: View {
    let icon: GameIcon
    var color: Color = Palette.royal
    var size: CGFloat = 50
    var label: String = ""
    let action: () -> Void

    var body: some View {
        Button {
            feedback()
            action()
        } label: {
            IconView(icon: icon, size: size * 0.48).frame(width: size, height: size)
        }
        .buttonStyle(CandyButtonStyle(color: color, shape: AnyShape(Circle())))
        .accessibilityLabel(label)
    }
}

// MARK: - Counters & bars

struct CounterPill: View {
    enum Kind { case diamonds, stars }
    let kind: Kind
    let value: Int
    var goal: Int?

    var body: some View {
        HStack(spacing: 6) {
            Group {
                if kind == .diamonds { DiamondIcon(size: 26) } else { StarCoin(size: 26) }
            }
            Text(goal.map { "\(value)/\($0)" } ?? "\(value)")
                .font(.game(17))
                .foregroundStyle(Palette.text)
                .contentTransition(.numericText(value: Double(value)))
                .animation(.spring, value: value)
        }
        .padding(.leading, 6).padding(.trailing, 12).padding(.vertical, 4)
        .background(Capsule().fill(.white.opacity(0.92)))
        .overlay(Capsule().stroke(kind == .diamonds ? Palette.sky : Palette.yellow, lineWidth: 2.5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(kind == .diamonds ? "\(value) diamonds" : "\(value) stars")
    }
}

struct GameProgressBar: View {
    var value: Double
    var colors: [Color] = [Palette.sky, Palette.royal]
    var height: CGFloat = 18

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.text.opacity(0.15))
                Capsule()
                    .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(height, geo.size.width * min(1, max(0, value))))
                    .overlay(alignment: .top) {
                        Capsule().fill(.white.opacity(0.45)).frame(height: height * 0.3).padding(.horizontal, 6).padding(.top, 3)
                    }
                    .animation(.spring(response: 0.6), value: value)
            }
        }
        .frame(height: height)
        .overlay(Capsule().stroke(.white, lineWidth: 2))
    }
}

struct RatingStars: View {
    let rating: Int
    var size: CGFloat = 20

    var body: some View {
        HStack(spacing: size * 0.1) {
            ForEach(1...3, id: \.self) { i in
                StarCoin(size: size, face: false)
                    .saturation(i <= rating ? 1 : 0)
                    .opacity(i <= rating ? 1 : 0.35)
                    .offset(y: i == 2 ? -size * 0.2 : 0)
            }
        }
        .accessibilityLabel("\(rating) of 3 stars")
    }
}

struct RewardRow: View {
    let reward: Reward
    var size: CGFloat = 26

    var body: some View {
        HStack(spacing: 14) {
            if reward.stars > 0 {
                HStack(spacing: 4) { StarCoin(size: size); Text("+\(reward.stars)") }
            }
            if reward.diamonds > 0 {
                HStack(spacing: 4) { DiamondIcon(size: size); Text("+\(reward.diamonds)") }
            }
        }
        .font(.game(size * 0.7))
        .foregroundStyle(Palette.text)
    }
}

struct NotificationDot: View {
    @State private var pulse = false
    @Environment(\.gameReduceMotion) private var reduceMotion

    var body: some View {
        Circle().fill(Palette.hotPink)
            .overlay(Circle().stroke(.white, lineWidth: 2.5))
            .frame(width: 18, height: 18)
            .scaleEffect(pulse ? 1.2 : 0.9)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 0.7).repeatForever()) { pulse = true }
            }
            .accessibilityLabel("New")
    }
}

// MARK: - Panels & headers

struct GamePanel: ViewModifier {
    var color: Color = .white

    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: 26).fill(color.opacity(0.94)))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(.white, lineWidth: 3))
            .shadow(color: Palette.deep.opacity(0.25), radius: 10, y: 6)
    }
}

extension View {
    func gamePanel(_ color: Color = .white) -> some View { modifier(GamePanel(color: color)) }

    /// Big outlined title text.
    func titleStyle(_ size: CGFloat = 30) -> some View {
        font(.game(size, .black))
            .foregroundStyle(.white)
            .shadow(color: Palette.deep, radius: 0, x: 0, y: 3)
            .shadow(color: Palette.deep.opacity(0.5), radius: 4)
    }
}

struct ScreenHeader: View {
    let title: String
    var onBack: (() -> Void)?
    @Environment(GameState.self) private var state

    var body: some View {
        HStack(spacing: 10) {
            if let onBack { RoundIconButton(icon: .back, color: Palette.royal, size: 46, label: "Back", action: onBack) }
            Text(title).titleStyle(Device.isPad ? 32 : 24).lineLimit(1).minimumScaleFactor(0.6)
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 4) {
                CounterPill(kind: .stars, value: state.data.stars)
                CounterPill(kind: .diamonds, value: state.data.totalDiamonds)
            }
            .scaleEffect(0.9, anchor: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }
}

struct CategoryTabs<T: Hashable>: View {
    let items: [T]
    @Binding var selection: T
    let title: (T) -> String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    let selected = item == selection
                    Button {
                        feedback()
                        withAnimation(.spring(response: 0.3)) { selection = item }
                    } label: {
                        Text(title(item)).font(.game(16))
                            .padding(.horizontal, 16).frame(height: 40)
                            .foregroundStyle(selected ? .white : Palette.text)
                    }
                    .buttonStyle(CandyButtonStyle(color: selected ? Palette.hotPink : .white))
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 6)
        }
    }
}

// MARK: - Popups

/// Dimmed overlay with a springy card.
struct PopupCard<Content: View>: View {
    @ViewBuilder let content: Content
    @State private var shown = false

    var body: some View {
        ZStack {
            Color(hex: 0x0E2257).opacity(0.45).ignoresSafeArea()
            content
                .padding(24)
                .frame(maxWidth: 420)
                .gamePanel()
                .padding(24)
                .scaleEffect(shown ? 1 : 0.6)
                .opacity(shown ? 1 : 0)
        }
        .onAppear { withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) { shown = true } }
    }
}

struct ConfirmDialog: View {
    let title: String
    let message: String
    let confirmTitle: String
    var confirmColor: Color = Palette.hotPink
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        PopupCard {
            VStack(spacing: 16) {
                Text(title).font(.game(26)).foregroundStyle(Palette.text).multilineTextAlignment(.center)
                Text(message).font(.game(17, .semibold)).foregroundStyle(Palette.text.opacity(0.8)).multilineTextAlignment(.center)
                HStack(spacing: 12) {
                    BigButton(title: "No", color: Palette.royal, height: 50, action: onCancel)
                    BigButton(title: confirmTitle, color: confirmColor, height: 50, action: onConfirm)
                }
            }
        }
    }
}

/// Simple confetti of stars and gems falling from the top.
struct ConfettiView: View {
    var count = 28
    @Environment(\.gameReduceMotion) private var reduceMotion
    @State private var start = Date()

    var body: some View {
        if reduceMotion { EmptyView() } else {
            TimelineView(.animation) { ctx in
                let t = ctx.date.timeIntervalSince(start)
                GeometryReader { geo in
                    ForEach(0..<count, id: \.self) { i in
                        let speed = 90 + Double((i * 37) % 80)
                        let y = (t * speed + Double((i * 53) % 400)).truncatingRemainder(dividingBy: geo.size.height + 80) - 40
                        let x = Double((i * 61) % 100) / 100 * geo.size.width + sin(t * 2 + Double(i)) * 18
                        Group {
                            switch i % 3 {
                            case 0: StarCoin(size: 18, face: false)
                            case 1: GemView(color: Palette.gems[i % 5], size: 18)
                            default: RoundedRectangle(cornerRadius: 2).fill(Palette.rainbow[i % 6]).frame(width: 8, height: 14)
                            }
                        }
                        .rotationEffect(.degrees(t * 90 + Double(i * 20)))
                        .position(x: x, y: y)
                    }
                }
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()
        }
    }
}
