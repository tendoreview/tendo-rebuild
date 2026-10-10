import SwiftUI

/// Grouped clinical table surface.
struct DataTable<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Theme.surface, in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 0.5))
    }
}

struct DataRow: View {
    let label: String
    let value: String
    var showsDivider: Bool = true
    var valueColor: Color = Theme.inkSecondary

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 16))
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            if showsDivider {
                Rectangle().fill(Theme.hairline).frame(height: 0.5).padding(.leading, 16)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct ProgressTrack: View {
    let fraction: Double
    var height: CGFloat = 4
    var tint: Color = Theme.accent
    var track: Color = Theme.surfaceSunk

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(track)
                Rectangle()
                    .fill(tint)
                    .frame(width: max(0, min(1, fraction)) * geo.size.width)
            }
        }
        .frame(height: height)
        .clipShape(.rect(cornerRadius: height / 2))
        .accessibilityHidden(true)
    }
}
