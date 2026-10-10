import SwiftUI

enum ArchiveFilter: String, CaseIterable, Hashable {
    case all = "ALL"
    case standard = "STANDARD"
    case special = "SPECIAL"
}

/// Permanent specimen records of every completed rebuild.
struct ArchiveView: View {
    @Environment(GameStore.self) private var store
    @State private var filter: ArchiveFilter = .all

    private let columns: [GridItem] = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private var records: [CompletedRebuild] {
        store.sortedCompleted.filter { record in
            switch filter {
            case .all: true
            case .standard: record.isStandardSpec
            case .special: !record.isStandardSpec
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(title: "Archive", subtitle: "\(store.state.completed.count) specimen records")
                SegmentedTabs(options: ArchiveFilter.allCases, selection: $filter) { $0.rawValue }
                if records.isEmpty {
                    VStack(spacing: 8) {
                        TrackedLabel(text: "No records on file", size: 12, color: Theme.ink, tracking: 3, weight: .semibold)
                        Text("Complete a reconstruction specification to create a specimen record.")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.inkSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(records) { record in
                            NavigationLink(value: YardRoute.specimen(record.number)) {
                                ArchiveCard(record: record)
                            }
                            .buttonStyle(PressableStyle())
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}

struct ArchiveCard: View {
    let record: CompletedRebuild

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Color(hex: 0xECE9E3)
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    RestoredChickenImage(visualId: record.visualId)
                        .padding(14)
                        .allowsHitTesting(false)
                }
                .clipShape(.rect(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 6) {
                TrackedLabel(text: "Rebuild \(record.number.rebuildCode)", size: 11, color: Theme.inkSecondary, tracking: 2.2)
                DashMark()
                Text(record.protocolName.uppercased())
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                StatusBadge()
                    .padding(.top, 2)
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 8)
        }
        .padding(8)
        .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
        .accessibilityElement(children: .combine)
    }
}
