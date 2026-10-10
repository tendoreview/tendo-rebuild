import SwiftUI

/// Cinematic opening card: the mark lands like a studio ident, then hands off to the app.
struct SplashView: View {
    var onFinished: () -> Void

    @State private var titleProgress: CGFloat = 0
    @State private var ruleProgress: CGFloat = 0
    @State private var bylineProgress: CGFloat = 0
    @State private var exitProgress: CGFloat = 0

    private let title = "TENDO REBUILD"

    var body: some View {
        ZStack {
            Theme.ink.ignoresSafeArea()
            GridBackdrop()
                .opacity(0.12)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Text(title)
                    .font(.display(34))
                    .tracking(CGFloat.lerp(-6, 8, titleProgress))
                    .scaleEffect(1 + (1 - titleProgress) * 0.55)
                    .opacity(min(titleProgress * 3, 1))
                    .blur(radius: (1 - titleProgress) * 6)
                    .foregroundStyle(Theme.canvas)

                // Accent rule draws outward from center under the mark.
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: ruleProgress * 210, height: 2)
                    .padding(.top, 22)

                Text("BY TENDO REVIEW")
                    .font(.mono(11, weight: .semibold))
                    .tracking(CGFloat.lerp(2, 7, bylineProgress))
                    .foregroundStyle(Theme.inkSecondary)
                    .opacity(bylineProgress)
                    .padding(.top, 16)
            }
            .padding(.horizontal, Theme.margin)
        }
        .opacity(1 - exitProgress)
        .scaleEffect(1 + exitProgress * 0.04)
        .ignoresSafeArea()
        .contentShape(.rect)
        .onTapGesture { finish() }
        .sensoryFeedback(.impact(weight: .heavy), trigger: titleProgress) { old, new in old == 0 && new > 0 }
        .task {
            withAnimation(.snappy(duration: 0.8)) {
                titleProgress = 1
            }
            try? await Task.sleep(for: .milliseconds(380))
            withAnimation(.easeOut(duration: 0.45)) {
                ruleProgress = 1
                bylineProgress = 1
            }
            try? await Task.sleep(for: .milliseconds(850))
            withAnimation(.easeInOut(duration: 0.45)) {
                exitProgress = 1
            }
            try? await Task.sleep(for: .milliseconds(460))
            onFinished()
        }
    }

    private func finish() {
        withAnimation(.easeInOut(duration: 0.3)) {
            exitProgress = 1
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(320))
            onFinished()
        }
    }
}

private extension CGFloat {
    static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * Swift.min(Swift.max(t, 0), 1)
    }
}
