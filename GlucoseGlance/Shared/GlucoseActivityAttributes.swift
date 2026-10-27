import ActivityKit
import Foundation

/// Live Activity data. Everything lives in ContentState so unit and range changes show up right away.
struct GlucoseActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var mgdl: Int
        var trend: GlucoseTrend
        var readingDate: Date
        var deltaMgdl: Int?
        var settings: AppSettings

        var valueText: String { settings.unit.display(mgdl) }
        var deltaText: String { settings.unit.displayDelta(deltaMgdl) }
        var status: GlucoseStatus { settings.status(for: mgdl) }
    }
}
