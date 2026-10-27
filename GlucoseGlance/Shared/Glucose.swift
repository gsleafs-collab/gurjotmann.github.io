import Foundation
import SwiftUI

/// Trend arrow reported by Dexcom alongside each reading.
enum GlucoseTrend: String, Codable, Hashable, CaseIterable {
    case unknown = "None"
    case doubleUp = "DoubleUp"
    case singleUp = "SingleUp"
    case fortyFiveUp = "FortyFiveUp"
    case flat = "Flat"
    case fortyFiveDown = "FortyFiveDown"
    case singleDown = "SingleDown"
    case doubleDown = "DoubleDown"
    case notComputable = "NotComputable"
    case rateOutOfRange = "RateOutOfRange"

    /// Older Share responses send the trend as a number instead of a name.
    private static let byIndex: [GlucoseTrend] = [
        .unknown, .doubleUp, .singleUp, .fortyFiveUp, .flat,
        .fortyFiveDown, .singleDown, .doubleDown, .notComputable, .rateOutOfRange,
    ]

    init(shareName: String) {
        self = GlucoseTrend(rawValue: shareName) ?? .unknown
    }

    init(shareIndex: Int) {
        self = Self.byIndex.indices.contains(shareIndex) ? Self.byIndex[shareIndex] : .unknown
    }

    var arrow: String {
        switch self {
        case .doubleUp: return "⇈"
        case .singleUp: return "↑"
        case .fortyFiveUp: return "↗"
        case .flat: return "→"
        case .fortyFiveDown: return "↘"
        case .singleDown: return "↓"
        case .doubleDown: return "⇊"
        case .unknown, .notComputable, .rateOutOfRange: return ""
        }
    }

    var label: String {
        switch self {
        case .doubleUp: return "Rising quickly"
        case .singleUp: return "Rising"
        case .fortyFiveUp: return "Rising slowly"
        case .flat: return "Steady"
        case .fortyFiveDown: return "Falling slowly"
        case .singleDown: return "Falling"
        case .doubleDown: return "Falling quickly"
        case .unknown, .notComputable, .rateOutOfRange: return "No trend"
        }
    }
}

/// A single CGM reading. Values are always stored in mg/dL, which is what Dexcom sends.
struct GlucoseReading: Codable, Hashable, Identifiable {
    let date: Date
    let mgdl: Int
    let trend: GlucoseTrend

    var id: Date { date }

    /// Fake data for previews and widget placeholders.
    static func samples(endingAt now: Date = .now) -> [GlucoseReading] {
        (0..<72).map { i in
            let mgdl = 125 + Int(45 * sin(Double(i) / 9))
            return GlucoseReading(date: now.addingTimeInterval(-Double(i) * 300), mgdl: mgdl, trend: .flat)
        }
    }
}

extension Array where Element == GlucoseReading {
    /// Readings are kept newest first.
    var latest: GlucoseReading? { first }

    /// Change from the previous reading, only if the two are roughly one interval apart.
    var deltaMgdl: Int? {
        guard count >= 2, self[0].date.timeIntervalSince(self[1].date) < 11 * 60 else { return nil }
        return self[0].mgdl - self[1].mgdl
    }
}

enum GlucoseUnit: String, Codable, Hashable, CaseIterable, Identifiable {
    case mmol
    case mgdl

    var id: String { rawValue }

    var label: String { self == .mmol ? "mmol/L" : "mg/dL" }

    func value(fromMgdl mgdl: Double) -> Double {
        self == .mmol ? mgdl / 18.0 : mgdl
    }

    func format(_ mgdl: Double) -> String {
        switch self {
        case .mmol: return String(format: "%.1f", mgdl / 18.0)
        case .mgdl: return String(Int(mgdl.rounded()))
        }
    }

    /// Dexcom reports 39 for "LOW" and 401 for "HIGH" when the sensor is out of its range.
    func display(_ mgdl: Int) -> String {
        if mgdl <= 39 { return "LOW" }
        if mgdl >= 401 { return "HIGH" }
        return format(Double(mgdl))
    }

    func displayDelta(_ delta: Int?) -> String {
        guard let delta else { return "" }
        switch self {
        case .mmol: return String(format: "%+.1f", Double(delta) / 18.0)
        case .mgdl: return String(format: "%+d", delta)
        }
    }
}

enum GlucoseStatus {
    case urgentLow, low, inRange, high

    var color: Color {
        switch self {
        case .urgentLow, .low: return .red
        case .inRange: return .green
        case .high: return .orange
        }
    }
}

/// User preferences shared by the app, widgets and Live Activity.
struct AppSettings: Codable, Hashable {
    var unit: GlucoseUnit = .mmol
    var lowMgdl: Double = 70     // 3.9 mmol/L
    var highMgdl: Double = 180   // 10.0 mmol/L

    static let urgentLowMgdl: Double = 55   // 3.1 mmol/L

    func status(for mgdl: Int) -> GlucoseStatus {
        let value = Double(mgdl)
        if value < Self.urgentLowMgdl { return .urgentLow }
        if value < lowMgdl { return .low }
        if value > highMgdl { return .high }
        return .inRange
    }
}

enum AppConfig {
    static let appGroup = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String
        ?? "group.com.gurjotmann.glucoseglance"
    static let keychainAccessGroup = Bundle.main.object(forInfoDictionaryKey: "KeychainAccessGroup") as? String
    static let backgroundRefreshID = "com.gurjotmann.glucoseglance.refresh"

    /// Dexcom sends a new reading every 5 minutes.
    static let readingInterval: TimeInterval = 5 * 60
    /// After this long without a new reading, the value is shown as stale.
    static let staleAfter: TimeInterval = 15 * 60

    static let disclaimer = "Glucose Glance is a personal convenience tool and is not a medical device. Readings can be delayed or missing. Always confirm with your Dexcom app, receiver or a fingerstick before making treatment decisions."
}
