import SwiftUI

/// Clinical documentation of a completed rebuild.
struct SpecimenRecordView: View {
    @Environment(GameStore.self) private var store
    let number: Int

    var body: some View {
        Group {
            if let record = store.state.completed.first(where: { $0.number == number }) {
                SpecimenRecordContent(record: record, configuration: store.configuration)
            } else {
                Text("Record unavailable.")
                    .foregroundStyle(Theme.inkSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle("Specimen Record")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}

struct SpecimenRecordContent: View {
    let record: CompletedRebuild
    let configuration: EngineConfiguration
    @State private var isBreakdownExpanded: Bool = false

    private static let materialOrder: [String] = ["boneInWings", "bonelessWings", "tenders", "nuggets", "drumsticks", "thighs", "sandwich", "whole", "other"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                RestoredChickenImage(visualId: record.visualId)
                    .frame(height: 230)
                    .frame(maxWidth: .infinity)
                    .background(alignment: .bottom) {
                        Ellipse()
                            .fill(RadialGradient(colors: [.black.opacity(0.14), .clear], center: .center, startRadius: 0, endRadius: 90))
                            .frame(width: 180, height: 22)
                    }
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 6) {
                    TrackedLabel(text: "Rebuild \(record.number.rebuildCode)", size: 12, color: Theme.inkSecondary, tracking: 3)
                    Text(record.protocolName.uppercased())
                        .font(.display(28))
                        .foregroundStyle(Theme.ink)
                    TrackedLabel(text: "Structural status: complete", size: 11, color: Theme.inkSecondary, tracking: 2.6)
                }
                .accessibilityElement(children: .combine)

                summaryTable
                materialRecord
                composition
                TrackedLabel(text: "Classification: \(ChickenArt.label(for: record.visualId))", size: 10, color: Theme.inkTertiary, tracking: 2)
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
    }

    private var summaryTable: some View {
        DataTable {
            DataRow(label: "Completed", value: record.completedDate.formatted(.dateTime.month(.abbreviated).day().year()))
            Button {
                withAnimation(.snappy) { isBreakdownExpanded.toggle() }
            } label: {
                HStack {
                    Text("Total Pieces Consumed")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text("\(record.totalPieces)")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.inkSecondary)
                        .monospacedDigit()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.inkSecondary)
                        .rotationEffect(.degrees(isBreakdownExpanded ? 180 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .overlay(alignment: .bottom) { Rectangle().fill(Theme.hairline).frame(height: 0.5).padding(.leading, 16) }
            .accessibilityHint("Shows material breakdown")
            .sensoryFeedback(.selection, trigger: isBreakdownExpanded)

            if isBreakdownExpanded {
                VStack(spacing: 0) {
                    ForEach(breakdownRows, id: \.0) { id, count in
                        HStack {
                            Text(configuration.chickenTypeName(id))
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.inkSecondary)
                            Spacer()
                            Text("\(count)")
                                .font(.mono(14))
                                .foregroundStyle(Theme.inkSecondary)
                        }
                        .padding(.leading, 32)
                        .padding(.trailing, 16)
                        .padding(.vertical, 6)
                    }
                }
                .padding(.vertical, 6)
                .background(Theme.canvas.opacity(0.5))
                .overlay(alignment: .bottom) { Rectangle().fill(Theme.hairline).frame(height: 0.5).padding(.leading, 16) }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            DataRow(label: "Restaurants Involved", value: "\(record.restaurantCount)")
            DataRow(label: "Cities Involved", value: "\(record.cities.count)")
            DataRow(label: "States Involved", value: "\(record.states.count)")
            DataRow(label: "Sauces Involved", value: "\(record.sauceCount)")
            DataRow(label: "Average Tendo Score", value: record.averageScore.map { $0.oneDecimal } ?? "—")
            DataRow(label: "Time to Completion", value: "\(record.daysToCompletion) Days", showsDivider: false)
        }
    }

    private var breakdownRows: [(String, Int)] {
        Self.materialOrder.compactMap { id in
            let c = record.piecesByType[id] ?? 0
            return c > 0 ? (id, c) : nil
        }
    }

    private var materialRecord: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Material record")
            DataTable {
                let ids = Self.materialOrder.filter { $0 != "whole" || (record.piecesByType[$0] ?? 0) > 0 }
                ForEach(Array(ids.enumerated()), id: \.element) { index, id in
                    DataRow(label: configuration.chickenTypeName(id), value: "\(record.piecesByType[id] ?? 0)", showsDivider: index < ids.count - 1)
                }
            }
        }
    }

    private var composition: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Composition")
            DataTable {
                ForEach(Array(record.composition.enumerated()), id: \.element.id) { index, entry in
                    DataRow(label: entry.label, value: "\(Int((entry.share * 100).rounded()))%", showsDivider: index < record.composition.count - 1)
                }
            }
        }
    }
}
