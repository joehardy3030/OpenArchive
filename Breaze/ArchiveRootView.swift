import SwiftUI

/// Root SwiftUI shell: hosts the tab layout and global mini player.
struct ArchiveRootView: View {
    @EnvironmentObject private var playerViewModel: PlayerViewModel
    @EnvironmentObject private var deepLinkRouter: DeepLinkRouter

    @State private var selectedTab: Tab = .bands
    @State private var showFullPlayer = false

    enum Tab {
        case bands
        case myTapes
        case search
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                CollectionsView()
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        Color.clear.frame(height: playerViewModel.currentShow != nil ? 70 : 0)
                    }
                    .tag(Tab.bands)
                    .tabItem {
                        Label("Bands", systemImage: "music.note.list")
                    }

                DownloadsView()
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        Color.clear.frame(height: playerViewModel.currentShow != nil ? 70 : 0)
                    }
                    .tag(Tab.myTapes)
                    .tabItem {
                        Label("My Tapes", systemImage: "tray.full")
                    }

                SearchView()
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        Color.clear.frame(height: playerViewModel.currentShow != nil ? 70 : 0)
                    }
                    .tag(Tab.search)
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }
            }

            if playerViewModel.currentShow != nil {
                MiniPlayerBar(showFullPlayer: $showFullPlayer)
                    .environmentObject(playerViewModel)
                    .padding(.horizontal)
                    .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showFullPlayer, onDismiss: {
            if let (metadata, showType, model) = deepLinkRouter.pendingNavigation {
                deepLinkRouter.pendingNavigation = nil
                deepLinkRouter.navigate(to: metadata, showType: showType, model: model)
            }
        }) {
            FullPlayerView()
                .environmentObject(playerViewModel)
                .environmentObject(deepLinkRouter)
        }
        .onReceive(deepLinkRouter.$pendingShow) { show in
            guard show != nil else { return }
            selectedTab = .bands
        }
    }
}

/// Compact bar shown above the tab bar when audio is loaded.
struct MiniPlayerBar: View {
    @EnvironmentObject private var playerViewModel: PlayerViewModel
    @Binding var showFullPlayer: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(playerViewModel.currentShow?.metadata?.creator ?? "Chateau Archive")
                    .font(.headline)
                    .lineLimit(1)
                if let venue = playerViewModel.currentShow?.metadata?.venue {
                    Text(venue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Text(currentTrackName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .contentShape(Rectangle())
            .onTapGesture { showFullPlayer = true }

            Spacer()

            Button { playerViewModel.skipBackward() } label: {
                Image(systemName: "backward.fill")
                    .font(.body)
                    .padding(10)
            }

            Button { playerViewModel.togglePlayPause() } label: {
                Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .padding(10)
            }

            Button { playerViewModel.skipForward() } label: {
                Image(systemName: "forward.fill")
                    .font(.body)
                    .padding(10)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(radius: 3)
        .onTapGesture { showFullPlayer = true }
    }

    private var currentTrackName: String {
        guard let tracks = playerViewModel.currentShow?.mp3Array,
              playerViewModel.currentTrackIndex < tracks.count else {
            return playerViewModel.currentShow?.metadata?.date ?? ""
        }
        let t = tracks[playerViewModel.currentTrackIndex]
        return t.title ?? t.name ?? ""
    }
}
