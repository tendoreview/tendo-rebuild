import SwiftUI

@main
struct TendoRebuildApp: App {
    @State private var store: GameStore = GameStore()
    @State private var isSplashVisible: Bool = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(store)
                if isSplashVisible {
                    SplashView { isSplashVisible = false }
                        .transition(.opacity)
                        .zIndex(10)
                }
            }
            .preferredColorScheme(.light)
        }
    }
}
