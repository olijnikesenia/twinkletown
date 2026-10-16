import SwiftUI

// MARK: - Screen 3: Character selection

struct CharacterSelectScreen: View {
    let firstTime: Bool
    let onDone: () -> Void

    @Environment(GameState.self) private var state
    @State private var picked: Companion = .bibi
    @State private var cheer = false
    @State private var nickname = ""

    var body: some View {
        ZStack {
            MagicBackground(colors: [Palette.violet, Palette.lilac, Palette.pink.opacity(0.8)])
            VStack(spacing: 10) {
                if firstTime {
                    Text("Choose your friend!").titleStyle(Device.isPad ? 40 : 30).padding(.top, 10)
                } else {
                    ScreenHeader(title: "Choose a friend", onBack: onDone)
                }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 24) { preview.frame(width: 360); VStack(spacing: 16) { grid; controls }.frame(width: 420) }
                        .frame(minWidth: 820)
                    VStack(spacing: 10) { preview; grid; controls }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .onAppear {
            picked = state.data.companion ?? .bibi
            nickname = state.data.nickname
        }
    }

    private var preview: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle().fill(picked.theme.opacity(0.6)).frame(width: 200).blur(radius: 6)
                CompanionView(companion: picked, appearance: state.data.appearance, size: Device.isPad ? 220 : 170, happy: cheer)
                    .id(picked)
                    .transition(.scale.combined(with: .opacity))
            }
            Text(picked.name).titleStyle(28)
            Text(picked.blurb).font(.game(17, .semibold)).foregroundStyle(.white).multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
    }

    private var grid: some View {
        HStack(spacing: 10) {
            ForEach(Companion.allCases) { c in
                Button {
                    feedback(.flip)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { picked = c }
                    cheer = true
                    Task { try? await Task.sleep(for: .seconds(1.2)); cheer = false }
                } label: {
                    VStack(spacing: 0) {
                        CompanionArt(companion: c).frame(width: 200, height: 240).scaleEffect(0.32).frame(width: 64, height: 76)
                        Text(c.shortName).font(.game(15)).foregroundStyle(Palette.text)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 20).fill(c.theme))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(picked == c ? Palette.hotPink : .white, lineWidth: picked == c ? 5 : 3))
                    .scaleEffect(picked == c ? 1.08 : 1)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(c.name)
            }
        }
        .padding(.horizontal, 16)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                IconView(icon: .person, color: Palette.royal, size: 24)
                TextField("Your name", text: $nickname)
                    .font(.game(20))
                    .foregroundStyle(Palette.text)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .onChange(of: nickname) { _, new in if new.count > 14 { nickname = String(new.prefix(14)) } }
            }
            .padding(.horizontal, 16).frame(height: 52)
            .background(Capsule().fill(.white))
            .overlay(Capsule().stroke(Palette.sky, lineWidth: 3))

            BigButton(title: firstTime ? "Let's go with \(picked.shortName)!" : "Choose \(picked.shortName)",
                      icon: .check, color: Palette.hotPink, height: 62) {
                state.selectCompanion(picked)
                let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
                state.data.nickname = trimmed.isEmpty ? "Twinkler" : trimmed
                feedback(.reward, haptic: .medium)
                onDone()
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}
