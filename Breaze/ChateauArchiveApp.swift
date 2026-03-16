import SwiftUI

/// SwiftUI entry point for Chateau Archive.
@main
struct ChateauArchiveApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var playerViewModel = PlayerViewModel.shared
    @StateObject private var deepLinkRouter = DeepLinkRouter()

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ArchiveRootView()
                .environmentObject(playerViewModel)
                .environmentObject(deepLinkRouter)
                .onOpenURL { url in
                    deepLinkRouter.handle(url: url)
                }
                .onAppear {
                    playerViewModel.restorePlaybackIfAvailable()
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                AudioPlayerArchive.shared.savePlaybackState()
            }
        }
    }
}
