import SwiftUI

enum AppTab: Hashable {
    case quest
    case yard
    case log
    case map
    case you
}

/// Root: onboarding gate, five-part tab navigation, and the global log flow.
struct ContentView: View {
    @Environment(GameStore.self) private var store
    @State private var selection: AppTab = .quest
    @State private var isLogPresented: Bool = false
    @State private var presetRestaurant: Restaurant?
    @State private var isCompletionPresented: Bool = false

    var body: some View {
        Group {
            if store.state.hasOnboarded {
                tabs
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: store.state.hasOnboarded)
        .tint(Theme.accent)
    }

    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { selection },
            set: { newValue in
                if newValue == .log {
                    presetRestaurant = nil
                    isLogPresented = true
                } else {
                    selection = newValue
                }
            }
        )
    }

    private var tabs: some View {
        TabView(selection: tabSelection) {
            Tab(value: AppTab.quest) {
                QuestView(
                    onLog: { openLog(nil) },
                    onFind: { selection = .map },
                    onComplete: { isCompletionPresented = true }
                )
            } label: {
                Label("QUEST", systemImage: "scope")
            }

            Tab(value: AppTab.yard) {
                YardView()
            } label: {
                Label {
                    Text("YARD")
                } icon: {
                    Image(systemName: "bird")
                }
            }

            Tab(value: AppTab.log) {
                Color.clear
            } label: {
                Label {
                    Text("LOG")
                } icon: {
                    Image(uiImage: LogTabIcon.image)
                }
            }

            Tab(value: AppTab.map) {
                RestaurantMapView(onLog: { openLog($0) })
            } label: {
                Label("MAP", systemImage: "map")
            }

            Tab(value: AppTab.you) {
                YouView()
            } label: {
                Label("YOU", systemImage: "person")
            }
        }
        .fullScreenCover(isPresented: $isLogPresented) {
            LogFlowView(presetRestaurant: presetRestaurant) { completed in
                isLogPresented = false
                selection = .quest
                if completed {
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(450))
                        isCompletionPresented = true
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isCompletionPresented) {
            RebuildCompleteView { isCompletionPresented = false }
        }
    }

    private func openLog(_ restaurant: Restaurant?) {
        presetRestaurant = restaurant
        isLogPresented = true
    }
}

/// Pre-rendered emphasized LOG tab glyph: orange disc with a white plus.
enum LogTabIcon {
    static let image: UIImage = {
        let size = CGSize(width: 34, height: 34)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            UIColor(red: 0.898, green: 0.325, blue: 0.102, alpha: 1).setFill()
            ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
            UIColor.white.setStroke()
            let path = UIBezierPath()
            path.lineWidth = 3
            path.lineCapStyle = .round
            path.move(to: CGPoint(x: 17, y: 9))
            path.addLine(to: CGPoint(x: 17, y: 25))
            path.move(to: CGPoint(x: 9, y: 17))
            path.addLine(to: CGPoint(x: 25, y: 17))
            path.stroke()
        }
        return img.withRenderingMode(.alwaysOriginal)
    }()
}
