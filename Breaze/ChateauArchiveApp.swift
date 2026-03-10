import SwiftUI

/// SwiftUI entry point for Chateau Archive.
@main
struct ChateauArchiveApp: App {
    /// Bridge to existing UIKit app delegate for notifications, audio session, etc.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var playerViewModel = PlayerViewModel.shared

    var body: some Scene {
        WindowGroup {
            ArchiveRootView()
                .environmentObject(playerViewModel)
        }
    }
}

