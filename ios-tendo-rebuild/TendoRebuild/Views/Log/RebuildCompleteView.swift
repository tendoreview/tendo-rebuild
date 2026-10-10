import SwiftUI

/// Transition from X-ray reconstruction to restored specimen, then archive.
struct RebuildCompleteView: View {
    @Environment(GameStore.self) private var store
    let onDone: () -> Void

    @State private var isRestored: Bool = false
    @State private var archived: CompletedRebuild?

    var body: some View {
        let record = archived ?? store.pendingRecord
        let p = store.configuration.rebuildProtocol(record.protocolId) ?? store.activeProtocol
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    TrackedLabel(text: "Rebuild \(record.number.rebuildCode)", size: 12, color: Theme.inkSecondary, tracking: 3)
                    Text(archived == nil ? "REBUILD COMPLETE" : "SPECIMEN ARCHIVED")
                        .font(.display(36))
                    TrackedLabel(text: p.name, size: 12, color: Theme.accent, tracking: 2.4, weight: .semibold)
                }

                ZStack {
                    GridBackdrop()
                        .mask(RadialGradient(colors: [.black, .clear], center: .center, startRadius: 30, endRadius: 200))
                    Image("chicken_xray_side")
                        .resizable()
                        .scaledToFit()
                        .opacity(isRestored ? 0 : 1)
                        .blur(radius: isRestored ? 12 : 0)
                    RestoredChickenImage(visualId: p.visualId)
                        .opacity(isRestored ? 1 : 0)
                        .scaleEffect(isRestored ? 1 : 0.94)
                    CornerBrackets().stroke(Theme.inkTertiary, lineWidth: 1)
                }
                .frame(height: 300)
                .accessibilityLabel("Restored specimen")

                TrackedLabel(text: "Structural status: complete", size: 11, color: Theme.complete, tracking: 2.6, weight: .semibold)

                DataTable {
                    DataRow(label: "Completed", value: record.completedDate.formatted(.dateTime.month(.abbreviated).day().year()))
                    DataRow(label: "Total Pieces Consumed", value: "\(record.totalPieces)")
                    DataRow(label: "Restaurants Involved", value: "\(record.restaurantCount)")
                    DataRow(label: "Cities Involved", value: "\(record.cities.count)")
                    DataRow(label: "Sauces Involved", value: "\(record.sauceCount)")
                    DataRow(label: "Average Tendo Score", value: record.averageScore.map { $0.oneDecimal } ?? "—")
                    DataRow(label: "Time to Completion", value: "\(record.daysToCompletion) Days", showsDivider: false)
                }

                if archived != nil {
                    VStack(alignment: .leading, spacing: 6) {
                        TrackedLabel(text: "Next specification", size: 11, color: Theme.inkSecondary, tracking: 3)
                        Text("REBUILD \(store.state.active.number.rebuildCode) — \(store.activeProtocol.name.uppercased())")
                            .font(.system(size: 18, weight: .heavy))
                        Text(store.activeProtocol.summary)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface, in: .rect(cornerRadius: 14))
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, Theme.margin)
            .padding(.top, 32)
            .padding(.bottom, 120)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            Group {
                if archived == nil {
                    Button("ARCHIVE REBUILD") {
                        withAnimation(.snappy) { archived = store.archiveActiveRebuild() }
                    }
                } else {
                    Button("BEGIN REBUILD \(store.state.active.number.rebuildCode)", action: onDone)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Theme.margin)
            .padding(.vertical, 8)
            .background(Theme.canvas.opacity(0.96).ignoresSafeArea())
        }
        .sensoryFeedback(.success, trigger: isRestored)
        .sensoryFeedback(.impact(weight: .medium), trigger: archived != nil)
        .task {
            try? await Task.sleep(for: .milliseconds(700))
            withAnimation(.easeInOut(duration: 1.4)) { isRestored = true }
        }
    }
}
