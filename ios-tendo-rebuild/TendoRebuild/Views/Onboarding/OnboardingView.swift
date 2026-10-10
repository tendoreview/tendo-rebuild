import SwiftUI

/// Four-panel premise briefing, then an empty reconstruction.
struct OnboardingView: View {
    @Environment(GameStore.self) private var store
    @State private var page: Int = 0

    private struct Panel {
        let index: String
        let title: String
        let body: String
    }

    private let panels: [Panel] = [
        Panel(index: "01", title: "EAT CHICKEN.", body: "Log chicken you eat in the real world."),
        Panel(index: "02", title: "RECOVER MATERIAL.", body: "Different chicken products provide different reconstruction components."),
        Panel(index: "03", title: "REBUILD CHICKEN.", body: "Complete reconstruction specifications and archive finished chickens."),
        Panel(index: "04", title: "REPEAT.", body: "")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("TENDO").font(.system(size: 13, weight: .black)).tracking(3)
                Text("REBUILD").font(.system(size: 13, weight: .black)).tracking(3).foregroundStyle(Theme.accent)
                Spacer()
                TrackedLabel(text: "\(page + 1) / \(panels.count)", size: 11, color: Theme.inkTertiary, tracking: 2)
            }
            .padding(.horizontal, Theme.margin)
            .padding(.top, 12)

            TabView(selection: $page) {
                ForEach(Array(panels.enumerated()), id: \.offset) { i, panel in
                    VStack(alignment: .leading, spacing: 18) {
                        illustration(for: i)
                            .frame(maxWidth: .infinity)
                            .frame(height: 320)
                        TrackedLabel(text: "Procedure \(panel.index)", size: 11, color: Theme.accent, tracking: 3, weight: .semibold)
                        Text(panel.title)
                            .font(.display(44))
                            .minimumScaleFactor(0.7)
                            .lineLimit(2)
                        if !panel.body.isEmpty {
                            Text(panel.body)
                                .font(.system(size: 18))
                                .foregroundStyle(Theme.inkSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, Theme.margin)
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 6) {
                ForEach(0..<panels.count, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? Theme.ink : Theme.hairline)
                        .frame(width: i == page ? 24 : 8, height: 4)
                }
            }
            .animation(.snappy, value: page)
            .padding(.horizontal, Theme.margin)
            .padding(.bottom, 20)

            VStack(spacing: 10) {
                if page < panels.count - 1 {
                    Button("CONTINUE") { withAnimation { page += 1 } }
                        .buttonStyle(PrimaryButtonStyle())
                } else {
                    Button("BEGIN REBUILD 001") { store.completeOnboarding(useSampleRecords: false) }
                        .buttonStyle(PrimaryButtonStyle())
                    Button("EXPLORE WITH SAMPLE RECORDS") { store.completeOnboarding(useSampleRecords: true) }
                        .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(.horizontal, Theme.margin)
            .padding(.bottom, 16)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .sensoryFeedback(.selection, trigger: page)
    }

    @ViewBuilder
    private func illustration(for index: Int) -> some View {
        ZStack {
            GridBackdrop()
                .mask(RadialGradient(colors: [.black, .clear], center: .center, startRadius: 20, endRadius: 190))
            switch index {
            case 0:
                VStack(spacing: 10) {
                    ForEach(["6 BONE-IN WINGS", "3 TENDERS", "8 NUGGETS"], id: \.self) { line in
                        HStack {
                            Text(line).font(.mono(15, weight: .bold))
                            Spacer()
                            Text("LOGGED").font(.mono(11, weight: .bold)).foregroundStyle(Theme.complete)
                        }
                        .padding(14)
                        .background(Theme.surface, in: .rect(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 20)
            case 1:
                ReconstructionView(fills: ["wing": 0.8, "breast": 0.2, "leg": 0, "thigh": 0, "misc": 0.1], focusRegion: "wing", showsCallouts: true)
                    .padding(24)
            case 2:
                ReconstructionView(fills: ["wing": 1, "breast": 1, "leg": 1, "thigh": 0.7, "misc": 0.9], focusRegion: "thigh", showsCallouts: false)
                    .padding(24)
            default:
                RestoredChickenImage(visualId: "standard")
                    .padding(30)
            }
            CornerBrackets().stroke(Theme.inkTertiary, lineWidth: 1)
        }
    }
}
