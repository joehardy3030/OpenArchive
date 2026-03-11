# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Chateau Archive** is an iOS music player app for streaming and downloading live Grateful Dead performances from archive.org. It supports other creators/collections as well.

## Build & Run

- Always open `Breaze.xcworkspace` (not `Breaze.xcodeproj`) — CocoaPods requires the workspace.
- Install or update dependencies: `pod install`
- Build and run via Xcode targeting iOS 13.0+.
- There is no separate test suite or lint command defined in the project.

## Architecture

The app is in active **migration from UIKit to SwiftUI**. The `swiftUI` branch contains the new architecture; `main` is the older UIKit-based version.

### Entry Point & Navigation

```
ChateauArchiveApp (@main) → AppDelegate (audio session, permissions)
                          → PlayerViewModel.shared (global playback state)
                          → ArchiveRootView (3-tab SwiftUI nav: Bands, My Tapes, Search)
```

### Key Singletons

| Singleton | Role |
|-----------|------|
| `PlayerViewModel.shared` | Observable bridge between audio engine and SwiftUI UI |
| `AudioPlayerArchive.shared` | Core AVQueuePlayer-based playback engine |
| `LocalDatabase.shared` | GRDB SQLite database (downloads + share tables) |

### Layer Breakdown

- **SwiftUIViews/** — All new SwiftUI feature views, organized by tab (`BandsTab/`, `DownloadsTab/`, `SearchTab/`, `Player/`)
- **Breaze/** — App target root: entry point, AppDelegate, ArchiveRootView, PlayerViewModel, Info.plist
- **Network/ArchiveAPI.swift** — All archive.org API calls (search, metadata fetching)
- **MediaPlayers/AudioPlayerArchive.swift** — AVQueuePlayer, remote command center, background audio, playback state persistence
- **Database/LocalDatabase.swift** — GRDB schema and queries for local downloads
- **Models/** — Data structures: `ShowMetadataModel`, `PlaybackState`, `CollectionConfig`, `ChateauGPTModel`
- **CarPlay/** — CarPlay scene delegate and template manager
- **ViewControllers/** — Legacy UIKit controllers (being phased out)

### Data Flow

1. `ArchiveAPI` fetches show/track metadata from archive.org
2. `AudioPlayerArchive` queues and plays tracks (streaming URLs or local files)
3. `PlayerViewModel` observes `AudioPlayerArchive` via Notifications (`.playbackStarted`, `.playbackPaused`, `.playbackStopped`) and KVO, publishing state to SwiftUI
4. SwiftUI views subscribe to `PlayerViewModel` via `@ObservedObject` / `@StateObject`

### Persistence

- Playback state is saved on app background and restored on next launch
- Downloaded shows are stored in SQLite via GRDB (`downloads` table)
- Deep linking supported via `chateauarchive://` URL scheme

### Dependencies (CocoaPods)

- **Alamofire** — networking
- **SwiftyJSON** — JSON parsing
- **Signals** — event handling
- **GRDB.swift ~6.0** — SQLite ORM
