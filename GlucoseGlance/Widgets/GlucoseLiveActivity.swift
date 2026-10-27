import ActivityKit
import SwiftUI
import WidgetKit

/// Lock Screen banner plus the Dynamic Island "bubble" at the top of the screen.
struct GlucoseLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GlucoseActivityAttributes.self) { context in
            LockScreenLiveActivityView(state: context.state, isStale: context.isStale)
                .activityBackgroundTint(Color.black.opacity(0.7))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let state = context.state
            let color = context.isStale ? Color.gray : state.status.color

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(state.valueText)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                        Text(state.trend.arrow)
                            .font(.title2.weight(.semibold))
                    }
                    .foregroundStyle(color)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text(state.deltaText)
                            .font(.headline)
                        Text(state.settings.unit.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.isStale {
                        Text("No new reading since \(state.readingDate.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else {
                        Text("\(state.trend.label) · updated \(state.readingDate.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Text(state.valueText)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(color)
            } compactTrailing: {
                Text(context.isStale ? "?" : state.trend.arrow)
                    .foregroundStyle(color)
            } minimal: {
                Text(state.valueText)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(color)
            }
        }
    }
}

private struct LockScreenLiveActivityView: View {
    let state: GlucoseActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        HStack {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(state.valueText)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                Text(state.trend.arrow)
                    .font(.system(size: 30, weight: .semibold))
            }
            .foregroundStyle(isStale ? Color.gray : state.status.color)
            .strikethrough(isStale)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(state.deltaText) \(state.settings.unit.label)")
                    .font(.headline)
                    .foregroundStyle(.white)
                if isStale {
                    Text("No recent data")
                        .font(.caption)
                        .foregroundStyle(.red)
                } else {
                    Text(state.readingDate, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding()
    }
}
