import SwiftUI

enum YardRoute: Hashable {
    case archive
    case specimen(Int)
}

/// Collection environment: completed chickens on site at the facility.
struct YardView: View {
    @Environment(GameStore.self) private var store
    @State private var path: NavigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                YardScene(specimens: Array(store.sortedCompleted.prefix(YardScene.slots.count)))
                    .ignoresSafeArea()
                VStack(spacing: 0) {
                    header
                    Spacer()
                    featured
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: YardRoute.self) { route in
                switch route {
                case .archive:
                    ArchiveView()
                case .specimen(let number):
                    SpecimenRecordView(number: number)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("THE YARD")
                    .font(.display(40))
                    .foregroundStyle(Theme.ink)
                TrackedLabel(text: "\(store.state.completed.count) rebuilds complete", size: 12, color: Theme.inkSecondary, tracking: 4)
            }
            Spacer()
            NavigationLink(value: YardRoute.archive) {
                HStack(spacing: 6) {
                    Text("VIEW ARCHIVE")
                        .font(.system(size: 13, weight: .heavy))
                        .tracking(0.6)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .heavy))
                }
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 16)
                .frame(height: 44)
                .glassCapsule()
            }
            .buttonStyle(PressableStyle())
            .padding(.top, 4)
        }
        .padding(.horizontal, Theme.margin)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var featured: some View {
        let front = Array(store.sortedCompleted.prefix(2))
        if front.isEmpty {
            VStack(spacing: 6) {
                TrackedLabel(text: "No specimens on site", size: 12, color: Theme.ink, tracking: 3, weight: .semibold)
                Text("Completed reconstructions are transferred here.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(LinearGradient(colors: [Theme.canvas.opacity(0), Theme.canvas.opacity(0.95)], startPoint: .top, endPoint: .center))
        } else {
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(front.enumerated()), id: \.element.id) { index, record in
                    NavigationLink(value: YardRoute.specimen(record.number)) {
                        VStack(alignment: .leading, spacing: 6) {
                            TrackedLabel(text: "Rebuild \(record.number.rebuildCode)", size: 11, color: Theme.inkSecondary, tracking: 2.4)
                            DashMark()
                            Text(record.protocolName.uppercased())
                                .font(.system(size: 17, weight: .heavy))
                                .foregroundStyle(Theme.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, index == 0 ? 0 : 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableStyle())
                    if index == 0 && front.count > 1 {
                        Rectangle().fill(Theme.hairline).frame(width: 1, height: 52)
                    }
                }
            }
            .padding(.horizontal, Theme.margin)
            .padding(.top, 28)
            .padding(.bottom, 12)
            .background(LinearGradient(colors: [Theme.canvas.opacity(0), Theme.canvas.opacity(0.96), Theme.canvas], startPoint: .top, endPoint: .bottom))
        }
    }
}

/// Illustrated facility yard with restored chickens placed at depth.
struct YardScene: View {
    let specimens: [CompletedRebuild]

    struct Slot {
        let x: CGFloat
        let baseline: CGFloat
        let height: CGFloat
        let mirrored: Bool
    }

    /// Front slots first; most recent specimens take the nearest positions.
    static let slots: [Slot] = [
        Slot(x: 0.31, baseline: 0.775, height: 0.29, mirrored: true),
        Slot(x: 0.73, baseline: 0.735, height: 0.25, mirrored: false),
        Slot(x: 0.11, baseline: 0.645, height: 0.155, mirrored: true),
        Slot(x: 0.90, baseline: 0.655, height: 0.16, mirrored: false),
        Slot(x: 0.52, baseline: 0.625, height: 0.12, mirrored: true),
        Slot(x: 0.30, baseline: 0.59, height: 0.085, mirrored: false),
        Slot(x: 0.70, baseline: 0.588, height: 0.08, mirrored: true)
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .topLeading) {
                Theme.canvas
                    .overlay {
                        Image("concrete_yard_enclosure")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                    .clipped()
                    .overlay {
                        LinearGradient(colors: [Theme.canvas.opacity(0.92), Theme.canvas.opacity(0)], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.26))
                            .allowsHitTesting(false)
                    }

                floorStencil(width: w, height: h)

                ForEach(Array(specimens.enumerated()).reversed(), id: \.element.id) { index, record in
                    let slot = Self.slots[index]
                    let size = slot.height * h
                    NavigationLink(value: YardRoute.specimen(record.number)) {
                        ZStack(alignment: .bottom) {
                            Ellipse()
                                .fill(RadialGradient(colors: [.black.opacity(0.22), .clear], center: .center, startRadius: 0, endRadius: size * 0.35))
                                .frame(width: size * 0.8, height: size * 0.12)
                                .offset(y: size * 0.03)
                            RestoredChickenImage(visualId: record.visualId)
                                .scaleEffect(x: slot.mirrored ? -1 : 1, y: 1)
                                .frame(width: size, height: size)
                        }
                        .frame(width: size, height: size)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("Rebuild \(record.number.rebuildCode), \(record.protocolName)")
                    .position(x: slot.x * w, y: slot.baseline * h - size / 2)
                }
            }
        }
    }

    private func floorStencil(width: CGFloat, height: CGFloat) -> some View {
        Text("TR · YARD 02")
            .font(.system(size: 44, weight: .black))
            .tracking(6)
            .foregroundStyle(Theme.ink.opacity(0.07))
            .rotation3DEffect(.degrees(62), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
            .position(x: width * 0.62, y: height * 0.70)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
