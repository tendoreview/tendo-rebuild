import SwiftUI

struct SettingsView: View {
    @Environment(GameStore.self) private var store
    @State private var isConfirmingSample: Bool = false
    @State private var isConfirmingReset: Bool = false

    var body: some View {
        List {
            Section {
                NavigationLink(value: YouRoute.lab) {
                    Label("Protocol Lab", systemImage: "slider.horizontal.3")
                }
            } header: {
                Text("DEVELOPMENT")
            } footer: {
                Text("Create, duplicate and balance Rebuild Protocols. Not visible to standard operators.")
            }
            Section("DATA") {
                Button("Load Sample Records") { isConfirmingSample = true }
                Button("Restart Onboarding", role: .destructive) { isConfirmingReset = true }
            }
            Section("ABOUT") {
                LabeledContent("Rebuild in progress", value: store.state.active.number.rebuildCode)
                LabeledContent("Protocols on file", value: "\(store.configuration.protocols.count)")
                LabeledContent("Configuration version", value: "\(store.configuration.version)")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.canvas)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .confirmationDialog("Replace current records with sample data?", isPresented: $isConfirmingSample, titleVisibility: .visible) {
            Button("Load Sample Records", role: .destructive) { store.completeOnboarding(useSampleRecords: true) }
        }
        .confirmationDialog("Return to onboarding? Current records will be replaced.", isPresented: $isConfirmingReset, titleVisibility: .visible) {
            Button("Restart", role: .destructive) { store.resetToOnboarding() }
        }
    }
}
