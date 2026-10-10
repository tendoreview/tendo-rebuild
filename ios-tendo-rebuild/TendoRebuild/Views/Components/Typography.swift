import SwiftUI

/// Monospaced, widely tracked documentation label.
struct TrackedLabel: View {
    let text: String
    var size: CGFloat = 11
    var color: Color = Theme.inkSecondary
    var tracking: CGFloat = 2.4
    var weight: Font.Weight = .medium

    var body: some View {
        Text(text.uppercased())
            .font(.mono(size, weight: weight))
            .tracking(tracking)
            .foregroundStyle(color)
    }
}

/// Short horizontal rule used between designation and name.
struct DashMark: View {
    var color: Color = Theme.ink

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 12, height: 2)
            .accessibilityHidden(true)
    }
}

/// Large headline with tracked subtitle, used at the top of root screens.
struct ScreenHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.display(40))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            TrackedLabel(text: subtitle, size: 12, color: Theme.inkSecondary, tracking: 4)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Section title in the spirit of an archival document.
struct SectionLabel: View {
    let text: String
    var trailing: String?

    var body: some View {
        HStack {
            TrackedLabel(text: text, size: 11, color: Theme.inkSecondary, tracking: 3)
            Spacer()
            if let trailing {
                TrackedLabel(text: trailing, size: 11, color: Theme.inkTertiary, tracking: 2)
            }
        }
        .padding(.horizontal, 4)
    }
}

struct StatusBadge: View {
    var text: String = "COMPLETE"
    var foreground: Color = Theme.complete
    var background: Color = Theme.completeSoft

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .heavy))
            .tracking(0.6)
            .foregroundStyle(foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(background, in: Capsule())
    }
}
