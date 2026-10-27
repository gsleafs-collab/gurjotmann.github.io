import SwiftUI
import WidgetKit

struct GlucoseEntry: TimelineEntry {
    let date: Date
    let readings: [GlucoseReading]
    let settings: AppSettings
    var errorMessage: String?

    var latest: GlucoseReading? { readings.latest }

    var isStale: Bool {
        guard let latest else { return true }
        return date.timeIntervalSince(latest.date) >= AppConfig.staleAfter
    }

    var valueText: String { latest.map { settings.unit.display($0.mgdl) } ?? "--" }
    var arrowText: String { isStale ? "" : latest?.trend.arrow ?? "" }
    var deltaText: String { isStale ? "" : settings.unit.displayDelta(readings.deltaMgdl) }
    var color: Color {
        guard let latest, !isStale else { return .secondary }
        return settings.status(for: latest.mgdl).color
    }
}

struct GlucoseProvider: TimelineProvider {
    func placeholder(in context: Context) -> GlucoseEntry {
        GlucoseEntry(date: .now, readings: GlucoseReading.samples(), settings: AppSettings())
    }

    func getSnapshot(in context: Context, completion: @escaping (GlucoseEntry) -> Void) {
        let cached = SharedStore.readings
        let readings = context.isPreview && cached.isEmpty ? GlucoseReading.samples() : cached
        completion(GlucoseEntry(date: .now, readings: readings, settings: SharedStore.settings))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GlucoseEntry>) -> Void) {
        Task {
            var readings = SharedStore.readings
            var errorMessage: String?
            do {
                readings = try await GlucoseFetcher.fetchAndCache()
            } catch {
                errorMessage = error.localizedDescription
            }

            let now = Date()
            let settings = SharedStore.settings
            var entries = [GlucoseEntry(date: now, readings: readings, settings: settings, errorMessage: errorMessage)]
            var nextFetch = now.addingTimeInterval(15 * 60)

            if let latest = readings.latest {
                // Second entry greys the widget out if no newer reading arrives in time.
                let staleAt = latest.date.addingTimeInterval(AppConfig.staleAfter)
                if staleAt > now {
                    entries.append(GlucoseEntry(date: staleAt, readings: readings, settings: settings))
                }
                // Ask to refresh just after the next reading is due. iOS may still delay this.
                let nextReading = latest.date.addingTimeInterval(AppConfig.readingInterval + 30)
                nextFetch = max(nextReading, now.addingTimeInterval(60))
            }

            completion(Timeline(entries: entries, policy: .after(nextFetch)))
        }
    }
}

struct GlucoseWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "GlucoseWidget", provider: GlucoseProvider()) { entry in
            GlucoseWidgetView(entry: entry)
        }
        .configurationDisplayName("Glucose")
        .description("Your latest Dexcom reading and trend.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

struct GlucoseWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: GlucoseEntry

    var body: some View {
        content
            .containerBackground(.fill.tertiary, for: .widget)
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryCircular: CircularView(entry: entry)
        case .accessoryRectangular: RectangularView(entry: entry)
        case .accessoryInline: InlineView(entry: entry)
        case .systemMedium: MediumView(entry: entry)
        default: SmallView(entry: entry)
        }
    }
}

// MARK: - Lock Screen

/// The round "bubble" on the Lock Screen: value with the trend arrow underneath.
private struct CircularView: View {
    let entry: GlucoseEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: -2) {
                Text(entry.valueText)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                if entry.isStale {
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.system(size: 11))
                } else {
                    Text(entry.arrowText)
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .padding(4)
            .widgetAccentable()
        }
    }
}

private struct RectangularView: View {
    let entry: GlucoseEntry

    var body: some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(entry.valueText) \(entry.arrowText)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .widgetAccentable()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(entry.deltaText)
                    .font(.caption)
                if let latest = entry.latest {
                    Text(latest.date, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            GlucoseChart(readings: entry.readings, settings: entry.settings, hours: 3, compact: true, endDate: entry.date)
        }
    }
}

private struct InlineView: View {
    let entry: GlucoseEntry

    var body: some View {
        Text("\(entry.valueText) \(entry.arrowText) \(entry.deltaText)")
    }
}

// MARK: - Home Screen

private struct ReadingSummary: View {
    let entry: GlucoseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.settings.unit.label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(entry.valueText)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(entry.arrowText)
                    .font(.system(size: 28, weight: .semibold))
            }
            .foregroundStyle(entry.color)
            Text(entry.deltaText)
                .font(.subheadline)
            Spacer(minLength: 0)
            if entry.latest == nil {
                Text(entry.errorMessage ?? "Open the app to sign in")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if entry.isStale {
                Text("No recent data")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if let latest = entry.latest {
                Text(latest.date, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SmallView: View {
    let entry: GlucoseEntry

    var body: some View {
        ReadingSummary(entry: entry)
    }
}

private struct MediumView: View {
    let entry: GlucoseEntry

    var body: some View {
        HStack(spacing: 12) {
            ReadingSummary(entry: entry)
                .frame(width: 110)
            GlucoseChart(readings: entry.readings, settings: entry.settings, hours: 3, compact: true, endDate: entry.date)
        }
    }
}
