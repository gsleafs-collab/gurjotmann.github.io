import ActivityKit
import Foundation
import WidgetKit

/// One refresh cycle: fetch from Dexcom, then push the result to widgets and the Live Activity.
@MainActor
enum GlucoseService {
    @discardableResult
    static func refresh() async throws -> [GlucoseReading] {
        let previousLatest = SharedStore.readings.latest
        let readings = try await GlucoseFetcher.fetchAndCache()
        if readings.latest != previousLatest {
            WidgetCenter.shared.reloadAllTimelines()
        }
        await LiveActivityManager.shared.update(readings: readings, settings: SharedStore.settings)
        return readings
    }
}

enum LiveActivityError: LocalizedError {
    case disabled
    case noData

    var errorDescription: String? {
        switch self {
        case .disabled: return "Live Activities are turned off. Enable them in Settings > Glucose Glance."
        case .noData: return "There's no recent reading to show yet."
        }
    }
}

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var activities: [Activity<GlucoseActivityAttributes>] {
        Activity<GlucoseActivityAttributes>.activities
    }

    var isRunning: Bool {
        activities.contains { $0.activityState == .active || $0.activityState == .stale }
    }

    func start(readings: [GlucoseReading], settings: AppSettings) throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { throw LiveActivityError.disabled }
        guard let content = content(readings: readings, settings: settings) else { throw LiveActivityError.noData }
        _ = try Activity.request(attributes: GlucoseActivityAttributes(), content: content, pushType: nil)
    }

    func update(readings: [GlucoseReading], settings: AppSettings) async {
        guard let content = content(readings: readings, settings: settings) else { return }
        for activity in activities where activity.content.state != content.state {
            await activity.update(content)
        }
    }

    func endAll() async {
        for activity in activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func content(readings: [GlucoseReading], settings: AppSettings) -> ActivityContent<GlucoseActivityAttributes.ContentState>? {
        guard let latest = readings.latest else { return nil }
        let state = GlucoseActivityAttributes.ContentState(
            mgdl: latest.mgdl,
            trend: latest.trend,
            readingDate: latest.date,
            deltaMgdl: readings.deltaMgdl,
            settings: settings
        )
        return ActivityContent(state: state, staleDate: latest.date.addingTimeInterval(AppConfig.staleAfter))
    }
}
