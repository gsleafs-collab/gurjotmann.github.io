import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var model: GlucoseViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var region: DexcomRegion = .outsideUS
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Username or email", text: $username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                } header: {
                    Text("Dexcom account")
                } footer: {
                    Text("Use the account of the person wearing the sensor (the one signed in to the Dexcom G6/G7 app). Share must be turned on in that app with at least one follower.")
                }

                Section("Region") {
                    Picker("Region", selection: $region) {
                        ForEach(DexcomRegion.allCases) { region in
                            Text(region.label).tag(region)
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task { await signIn() }
                    } label: {
                        if isWorking {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text("Connect").frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(username.isEmpty || password.isEmpty || isWorking)
                }

                Section {
                    Text(AppConfig.disclaimer)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Connect Dexcom")
        }
        .interactiveDismissDisabled()
    }

    private func signIn() async {
        isWorking = true
        errorMessage = nil
        do {
            try await model.signIn(username: username, password: password, region: region)
        } catch {
            errorMessage = error.localizedDescription
        }
        isWorking = false
    }
}
