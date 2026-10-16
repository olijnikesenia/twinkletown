import Foundation
import Observation

/// Local JSON save file. `url == nil` keeps everything in memory (tests, previews).
struct SaveStore {
    let url: URL?

    static let memory = SaveStore(url: nil)
    static var standard: SaveStore {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return SaveStore(url: dir.appendingPathComponent("twinkle_town_save.json"))
    }

    func load() -> PlayerData? {
        guard let url, let raw = try? Data(contentsOf: url) else { return nil }
        // shortcut: an undecodable save starts a new game; add migrations once the schema changes after release.
        return try? JSONDecoder().decode(PlayerData.self, from: raw)
    }

    func save(_ data: PlayerData) {
        guard let url, let raw = try? JSONEncoder().encode(data) else { return }
        try? raw.write(to: url, options: .atomic)
    }
}

/// Single source of truth for the whole game. Managers live in extensions (see Managers/).
@Observable
final class GameState {
    var data: PlayerData {
        didSet { scheduleSave() }
    }

    /// Achievements unlocked but not yet shown in a banner.
    var unlockQueue: [AchievementID] = []
    var pendingCelebration = false

    @ObservationIgnored let store: SaveStore
    @ObservationIgnored let now: () -> Date
    @ObservationIgnored let calendar: Calendar
    @ObservationIgnored private var saveScheduled = false

    init(store: SaveStore = .standard, now: @escaping () -> Date = Date.init, calendar: Calendar = .current) {
        self.store = store
        self.now = now
        self.calendar = calendar
        var loaded = store.load() ?? PlayerData()
        loaded.owned.formUnion(Catalog.starterIDs)
        self.data = loaded
        refreshDaily()
        refreshWeek()
        if data.totalDiamonds >= PlayerData.diamondGoal && !data.celebrationSeen {
            pendingCelebration = true
        }
    }

    /// Coalesces many mutations in one run-loop turn into a single disk write.
    private func scheduleSave() {
        guard !saveScheduled else { return }
        saveScheduled = true
        DispatchQueue.main.async { [weak self] in self?.saveNow() }
    }

    func saveNow() {
        saveScheduled = false
        store.save(data)
    }

    func resetProgress() {
        let settings = data.settings
        data = PlayerData()
        data.settings = settings
        unlockQueue = []
        pendingCelebration = false
        refreshDaily()
        refreshWeek()
        saveNow()
    }

    func restartOnboarding() {
        data.onboardingDone = false
    }
}
