import SwiftUI

/// Root SwiftUI shell: hosts the tab layout and global mini player.
struct ArchiveRootView: View {
    @EnvironmentObject private var playerViewModel: PlayerViewModel

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
                    .tag(Tab.bands)
                    .tabItem {
                        Label("Bands", systemImage: "music.note.list")
                    }

                DownloadsView()
                    .tag(Tab.myTapes)
                    .tabItem {
                        Label("My Tapes", systemImage: "tray.full")
                    }

                SearchView()
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
        .sheet(isPresented: $showFullPlayer) {
            FullPlayerView()
                .environmentObject(playerViewModel)
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
                Text(currentTrackName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .contentShape(Rectangle())
            .onTapGesture { showFullPlayer = true }

            Spacer()

            Button { playerViewModel.skipForward() } label: {
                Image(systemName: "forward.fill")
                    .font(.body)
            }
            .padding(.trailing, 4)

            Button { playerViewModel.togglePlayPause() } label: {
                Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
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
