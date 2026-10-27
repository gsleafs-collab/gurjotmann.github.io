import BackgroundTasks
import SwiftUI

@main
struct GlucoseGlanceApp: App {
    @StateObject private var model = GlucoseViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(model)
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                model.startPolling()
            case .background:
                model.stopPolling()
                BackgroundRefresh.schedule()
            default:
                break
            }
        }
        .backgroundTask(.appRefresh(AppConfig.backgroundRefreshID)) {
            BackgroundRefresh.schedule()
            _ = try? await GlucoseService.refresh()
        }
    }
}

enum BackgroundRefresh {
    /// iOS decides when this actually runs (often every 15 to 60 minutes), so it's a backup, not real time.
    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: AppConfig.backgroundRefreshID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: AppConfig.readingInterval)
        try? BGTaskScheduler.shared.submit(request)
    }
}
