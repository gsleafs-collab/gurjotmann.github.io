import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: GlucoseViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Units") {
                    Picker("Units", selection: $model.settings.unit) {
                        ForEach(GlucoseUnit.allCases) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    thresholdRow("Low", value: $model.settings.lowMgdl,
                                 range: 54...(model.settings.highMgdl - 18))
                    thresholdRow("High", value: $model.settings.highMgdl,
                                 range: (model.settings.lowMgdl + 18)...400)
                } header: {
                    Text("Target range")
                } footer: {
                    Text("Used to colour readings in the app, widgets and Live Activity.")
                }

                Section("Account") {
                    if let credentials = CredentialStore.load() {
                        LabeledContent("Signed in as", value: credentials.username)
                        LabeledContent("Region", value: credentials.region.label)
                    }
                    Button("Sign Out", role: .destructive) {
                        model.signOut()
                        dismiss()
                    }
                }

                Section("About") {
                    Text(AppConfig.disclaimer)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func thresholdRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        let unit = model.settings.unit
        // 1.8 mg/dL is 0.1 mmol/L
        let step = unit == .mmol ? 1.8 : 1
        return Stepper(value: value, in: range, step: step) {
            LabeledContent(title, value: "\(unit.format(value.wrappedValue)) \(unit.label)")
        }
    }
}
