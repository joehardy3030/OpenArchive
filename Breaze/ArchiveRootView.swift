import SwiftUI

/// Root SwiftUI shell: hosts the tab layout and global mini player.
struct ArchiveRootView: View {
    @EnvironmentObject private var playerViewModel: PlayerViewModel

    @State private var selectedTab: Tab = .bands

    enum Tab {
        case bands
        case myTapes
        case search
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                Text("Bands tab SwiftUI placeholder")
                    .tag(Tab.bands)
                    .tabItem {
                        Label("Bands", systemImage: "music.note.list")
                    }

                Text("My Tapes tab SwiftUI placeholder")
                    .tag(Tab.myTapes)
                    .tabItem {
                        Label("My Tapes", systemImage: "tray.full")
                    }

                Text("Search tab SwiftUI placeholder")
                    .tag(Tab.search)
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }
            }

            // Simple mini-player bar placeholder wired to PlayerViewModel.
            if playerViewModel.currentShow != nil {
                MiniPlayerBar()
                    .environmentObject(playerViewModel)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
    }
}

/// Very small SwiftUI bar that mirrors basic MiniPlayer information.
struct MiniPlayerBar: View {
    @EnvironmentObject private var playerViewModel: PlayerViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(playerViewModel.currentShow?.metadata?.creator ?? "Chateau Archive")
                    .font(.headline)
                    .lineLimit(1)
                if let date = playerViewModel.currentShow?.metadata?.date {
                    Text(date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Button(action: { playerViewModel.togglePlayPause() }) {
                Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(radius: 3)
    }
}

