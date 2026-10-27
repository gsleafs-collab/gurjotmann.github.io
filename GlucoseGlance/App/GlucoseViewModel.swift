import Foundation
import WidgetKit

@MainActor
final class GlucoseViewModel: ObservableObject {
    @Published private(set) var readings: [GlucoseReading]
    @Published private(set) var isSignedIn: Bool
    @Published private(set) var errorMessage: String?
    @Published private(set) var liveActivityOn: Bool
    @Published var settings: AppSettings {
        didSet {
            SharedStore.settings = settings
            WidgetCenter.shared.reloadAllTimelines()
            Task { await LiveActivityManager.shared.update(readings: readings, settings: settings) }
        }
    }

    private var pollTask: Task<Void, Never>?

    init() {
        readings = SharedStore.readings
        settings = SharedStore.settings
        isSignedIn = CredentialStore.load() != nil
        liveActivityOn = LiveActivityManager.shared.isRunning
    }

    func signIn(username: String, password: String, region: DexcomRegion) async throws {
        let credentials = DexcomCredentials(
            username: username.trimmingCharacters(in: .whitespaces),
            password: password,
            region: region
        )
        SharedStore.sessionID = nil
        // Fetch once before saving so bad credentials never get stored.
        let fetched = try await DexcomShareClient(credentials: credentials).latestReadings()
        try CredentialStore.save(credentials)
        SharedStore.readings = fetched
        readings = fetched
        errorMessage = nil
        isSignedIn = true
        WidgetCenter.shared.reloadAllTimelines()
        startPolling()
    }

    func signOut() {
        stopPolling()
        CredentialStore.delete()
        SharedStore.sessionID = nil
        SharedStore.readings = []
        readings = []
        isSignedIn = false
        liveActivityOn = false
        Task { await LiveActivityManager.shared.endAll() }
        WidgetCenter.shared.reloadAllTimelines()
    }

    func refresh() async {
        guard isSignedIn else { return }
        do {
            readings = try await GlucoseService.refresh()
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
        liveActivityOn = LiveActivityManager.shared.isRunning
    }

    /// While the app is open, check shortly after each new reading is due.
    func startPolling() {
        guard isSignedIn else { return }
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.refresh()
                try? await Task.sleep(for: .seconds(self.nextPollDelay()))
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    func setLiveActivity(_ on: Bool) {
        if on {
            do {
                try LiveActivityManager.shared.start(readings: readings, settings: settings)
                liveActivityOn = true
            } catch {
                errorMessage = error.localizedDescription
                liveActivityOn = false
            }
        } else {
            liveActivityOn = false
            Task { await LiveActivityManager.shared.endAll() }
        }
    }

    private func nextPollDelay() -> Double {
        guard let latest = readings.latest else { return 60 }
        let due = latest.date.addingTimeInterval(AppConfig.readingInterval + 15).timeIntervalSinceNow
        // Overdue readings get retried every 30 seconds.
        return min(max(due, 30), AppConfig.readingInterval + 15)
    }
}
