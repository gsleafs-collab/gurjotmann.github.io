import Charts
import SwiftUI

/// Scatter chart of readings with the target range shaded, used in the app and the medium widget.
struct GlucoseChart: View {
    let readings: [GlucoseReading]
    let settings: AppSettings
    var hours: Double = 3
    var compact = false
    var endDate: Date = .now

    var body: some View {
        let start = endDate.addingTimeInterval(-hours * 3600)
        let points = readings.filter { $0.date >= start }
        let unit = settings.unit
        let maxValue = points.map { unit.value(fromMgdl: Double($0.mgdl)) }.max() ?? 0
        let yTop = unit == .mmol ? max(15, maxValue + 1) : max(270, maxValue + 20)
        let yBottom = unit == .mmol ? 2.0 : 40.0

        Chart {
            RectangleMark(
                xStart: .value("Start", start),
                xEnd: .value("End", endDate),
                yStart: .value("Low", unit.value(fromMgdl: settings.lowMgdl)),
                yEnd: .value("High", unit.value(fromMgdl: settings.highMgdl))
            )
            .foregroundStyle(Color.green.opacity(0.15))

            ForEach(points) { reading in
                PointMark(
                    x: .value("Time", reading.date),
                    y: .value("Glucose", unit.value(fromMgdl: Double(reading.mgdl)))
                )
                .foregroundStyle(settings.status(for: reading.mgdl).color)
                .symbolSize(compact ? 10 : 28)
            }
        }
        .chartXScale(domain: start...endDate)
        .chartYScale(domain: yBottom...yTop)
        .chartXAxis(compact ? .hidden : .automatic)
        .chartYAxis(compact ? .hidden : .automatic)
    }
}
