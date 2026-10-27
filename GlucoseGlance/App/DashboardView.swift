import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var model: GlucoseViewModel
    @State private var hours: Double = 3
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    CurrentReadingCard(readings: model.readings, settings: model.settings)

                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Range", selection: $hours) {
                            Text("3h").tag(3.0)
                            Text("6h").tag(6.0)
                            Text("12h").tag(12.0)
                            Text("24h").tag(24.0)
                        }
                        .pickerStyle(.segmented)

                        GlucoseChart(readings: model.readings, settings: model.settings, hours: hours)
                            .frame(height: 240)
                    }
                    .padding()
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))

                    Toggle(isOn: Binding(
                        get: { model.liveActivityOn },
                        set: { model.setLiveActivity($0) }
                    )) {
                        Label("Live Activity", systemImage: "iphone.gen3.radiowaves.left.and.right")
                    }
                    .padding()
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))

                    if let error = model.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Text(AppConfig.disclaimer)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Glucose Glance")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .refreshable { await model.refresh() }
            .sheet(isPresented: $showingSettings) {
                SettingsView().environmentObject(model)
            }
            .fullScreenCover(isPresented: Binding(get: { !model.isSignedIn }, set: { _ in })) {
                LoginView().environmentObject(model)
            }
        }
    }
}

private struct CurrentReadingCard: View {
    let readings: [GlucoseReading]
    let settings: AppSettings

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            VStack(spacing: 6) {
                if let latest = readings.latest {
                    let age = context.date.timeIntervalSince(latest.date)
                    let stale = age >= AppConfig.staleAfter

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(settings.unit.display(latest.mgdl))
                            .font(.system(size: 84, weight: .bold, design: .rounded))
                        Text(latest.trend.arrow)
                            .font(.system(size: 52, weight: .semibold))
                    }
                    .foregroundStyle(stale ? Color.secondary : settings.status(for: latest.mgdl).color)
                    .strikethrough(stale)

                    Text("\(settings.unit.displayDelta(readings.deltaMgdl)) \(settings.unit.label)  ·  \(latest.trend.label)")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text(stale ? "No new data for \(Int(age / 60)) min" : ageText(age))
                        .font(.subheadline)
                        .foregroundStyle(stale ? Color.red : Color.secondary)
                } else {
                    ProgressView()
                    Text("Waiting for readings")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func ageText(_ age: TimeInterval) -> String {
        let minutes = Int(age / 60)
        return minutes < 1 ? "Just now" : "\(minutes) min ago"
    }
}
