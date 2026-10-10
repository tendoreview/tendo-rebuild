import SwiftUI

/// Internal configuration interface for Rebuild Protocols.
struct ProtocolLabView: View {
    @Environment(GameStore.self) private var store
    @State private var isConfirmingReset: Bool = false

    private var protocols: [RebuildProtocol] {
        store.configuration.protocols.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        List {
            Section {
                ForEach(protocols) { p in
                    NavigationLink(value: YouRoute.protocolEditor(p.id)) {
                        HStack(spacing: 12) {
                            RestoredChickenImage(visualId: p.visualId)
                                .frame(width: 40, height: 40)
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(p.name)
                                        .font(.system(size: 16, weight: .bold))
                                    if p.id == store.state.active.protocolId {
                                        Text("ACTIVE")
                                            .font(.mono(9, weight: .bold))
                                            .foregroundStyle(Theme.accent)
                                    }
                                }
                                Text("Difficulty \(p.difficulty) · \(Int(p.totalRequiredUnits)) units · \(p.completionRequirements.count) req.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.inkSecondary)
                            }
                            Spacer()
                            if !p.isActive {
                                Text("OFF")
                                    .font(.mono(10, weight: .bold))
                                    .foregroundStyle(Theme.inkTertiary)
                            }
                        }
                    }
                    .swipeActions {
                        if p.id != store.state.active.protocolId {
                            Button("Delete", role: .destructive) { store.deleteProtocol(id: p.id) }
                        }
                        Button("Duplicate") { _ = store.duplicateProtocol(p) }
                            .tint(Theme.ink)
                    }
                }
            } header: {
                Text("REBUILD PROTOCOLS")
            } footer: {
                Text("Swipe to duplicate or delete. Protocols are stored in the local database and processed by the rules engine without code changes.")
            }
            Section {
                Button {
                    _ = store.createProtocol()
                } label: {
                    Label("New Protocol", systemImage: "plus")
                }
                Button("Restore Factory Configuration", role: .destructive) { isConfirmingReset = true }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.canvas)
        .navigationTitle("Protocol Lab")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .confirmationDialog("Restore every protocol, quest and conversion rule to factory values?", isPresented: $isConfirmingReset, titleVisibility: .visible) {
            Button("Restore", role: .destructive) { store.resetConfiguration() }
        }
    }
}
