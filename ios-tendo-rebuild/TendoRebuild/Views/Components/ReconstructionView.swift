import SwiftUI

/// Anatomical region of the X-ray chicken, in normalized image coordinates.
struct AnatomyRegion: Identifiable {
    let id: String
    let rects: [CGRect]
    let label: String
    let calloutAnchor: CGPoint

    /// Regions tuned to the `chicken_xray_side` artwork.
    static let all: [AnatomyRegion] = [
        AnatomyRegion(id: "misc", rects: [CGRect(x: 0.0, y: 0.0, width: 0.34, height: 0.38), CGRect(x: 0.66, y: 0.16, width: 0.34, height: 0.40)], label: "MISC.", calloutAnchor: CGPoint(x: 0.86, y: 0.28)),
        AnatomyRegion(id: "breast", rects: [CGRect(x: 0.12, y: 0.34, width: 0.30, height: 0.36)], label: "BREAST", calloutAnchor: CGPoint(x: 0.22, y: 0.52)),
        AnatomyRegion(id: "wing", rects: [CGRect(x: 0.34, y: 0.32, width: 0.34, height: 0.22)], label: "WING", calloutAnchor: CGPoint(x: 0.52, y: 0.40)),
        AnatomyRegion(id: "thigh", rects: [CGRect(x: 0.40, y: 0.50, width: 0.44, height: 0.22)], label: "THIGH", calloutAnchor: CGPoint(x: 0.70, y: 0.60)),
        AnatomyRegion(id: "leg", rects: [CGRect(x: 0.28, y: 0.70, width: 0.50, height: 0.30)], label: "LEG", calloutAnchor: CGPoint(x: 0.52, y: 0.86))
    ]
}

/// The partially reconstructed X-ray chicken. Each region fills bottom-up with its material progress.
struct ReconstructionView: View {
    /// region id -> 0...1
    let fills: [String: Double]
    var focusRegion: String?
    var showsCallouts: Bool = true

    @State private var pulse: Bool = false

    private let aspect: CGFloat = 993.0 / 1011.0

    var body: some View {
        GeometryReader { geo in
            let size = fittedSize(in: geo.size)
            ZStack {
                ghost
                revealed(size: size)
                if showsCallouts {
                    overlays(size: size)
                }
            }
            .frame(width: size.width, height: size.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(aspect, contentMode: .fit)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) { pulse = true }
        }
        .accessibilityElement()
        .accessibilityLabel("Reconstruction diagram")
        .accessibilityValue(accessibilityText)
    }

    private var accessibilityText: String {
        AnatomyRegion.all.map { "\($0.label.capitalized) \(Int((fills[$0.id] ?? 1) * 100)) percent" }.joined(separator: ", ")
    }

    private func fittedSize(in size: CGSize) -> CGSize {
        let w = min(size.width, size.height * aspect)
        return CGSize(width: w, height: w / aspect)
    }

    private var ghost: some View {
        Image("chicken_xray_side")
            .resizable()
            .scaledToFit()
            .saturation(0)
            .contrast(0.7)
            .opacity(0.16)
    }

    private func revealed(size: CGSize) -> some View {
        Image("chicken_xray_side")
            .resizable()
            .scaledToFit()
            .mask {
                Canvas { context, canvasSize in
                    for region in AnatomyRegion.all {
                        let fill = max(0, min(1, fills[region.id] ?? 1))
                        guard fill > 0 else { continue }
                        for r in region.rects {
                            let rect = CGRect(x: r.minX * canvasSize.width, y: r.minY * canvasSize.height, width: r.width * canvasSize.width, height: r.height * canvasSize.height)
                            let revealHeight = rect.height * fill
                            let reveal = CGRect(x: rect.minX, y: rect.maxY - revealHeight, width: rect.width, height: revealHeight)
                            context.fill(Path(roundedRect: reveal, cornerRadius: 6), with: .color(.white))
                        }
                    }
                }
                .blur(radius: 5)
            }
            .animation(.easeInOut(duration: 0.9), value: fills)
    }

    private func overlays(size: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(AnatomyRegion.all.filter { (fills[$0.id] ?? 1) < 0.999 }) { region in
                let isFocus = region.id == focusRegion
                ForEach(Array(region.rects.enumerated()), id: \.offset) { _, r in
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isFocus ? Theme.accent : Theme.inkTertiary.opacity(0.6), style: StrokeStyle(lineWidth: isFocus ? 1.4 : 0.8, dash: [4, 4]))
                        .frame(width: r.width * size.width, height: r.height * size.height)
                        .offset(x: r.minX * size.width, y: r.minY * size.height)
                        .opacity(isFocus ? (pulse ? 1 : 0.35) : 0.8)
                }
                Text(isFocus ? "\(region.label) — REQUIRED" : region.label)
                    .font(.mono(9, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(isFocus ? .white : Theme.inkSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(isFocus ? Theme.accent : Theme.surface.opacity(0.9), in: .rect(cornerRadius: 3))
                    .fixedSize()
                    .position(x: region.calloutAnchor.x * size.width, y: region.calloutAnchor.y * size.height)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}
