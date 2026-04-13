# AGENTS.md

This file provides guidance to Codex and other AI agents when working with code in this repository.

## Project Overview

**Chateau Archive** is an iOS music player app for streaming and downloading live concert recordings. It supports Grateful Dead (via archive.org), Phish (via Phish.in audio + Phish.net metadata), and many other jam bands and collections from archive.org.

## Build & Run

- Always open `Breaze.xcworkspace` (not `Breaze.xcodeproj`) — CocoaPods requires the workspace.
- Install or update dependencies: `pod install`
- Build and run via Xcode targeting iOS 13.0+.
- There is no separate test suite or lint command defined in the project.
- Build number auto-incremented via `Scripts/increment_build_number.sh`.

## Architecture

The app uses **SwiftUI** throughout. The UIKit-to-SwiftUI migration is complete.

### Entry Point & Navigation

```
ChateauArchiveApp (@main) → AppDelegate (audio session, permissions)
                          → PlayerViewModel.shared (global playback state)
                          → DeepLinkRouter (chateauarchive:// URL handling)
                          → ArchiveRootView (3-tab SwiftUI nav: Bands, My Tapes, Search)
```

### Key Singletons

| Singleton | Role |
|-----------|------|
| `PlayerViewModel.shared` | Observable bridge between audio engine and SwiftUI UI |
| `AudioPlayerArchive.shared` | Core AVQueuePlayer-based playback engine |
| `LocalDatabase.shared` | GRDB SQLite database (downloads + share tables) |

### Layer Breakdown

- **SwiftUIViews/** — All SwiftUI feature views, organized by tab (`BandsTab/`, `DownloadsTab/`, `SearchTab/`, `Player/`)
- **Breaze/** — App target root: entry point, AppDelegate, ArchiveRootView, PlayerViewModel, Info.plist
- **Network/ArchiveAPI.swift** — archive.org API calls (search, metadata fetching)
- **Network/PhishInAPI.swift** — Phish.in API v2 client for Phish audience recordings (no API key required)
- **Network/PhishNetAPI.swift** — Phish.net API v5 client for Phish setlists, ratings, venues (API key in `PhishNetAPIKeys.plist`, gitignored)
- **Network/NetworkUtility.swift** — Shared networking helpers
- **MediaPlayers/AudioPlayerArchive.swift** — AVQueuePlayer, remote command center, background audio, playback state persistence
- **Database/LocalDatabase.swift** — GRDB schema and queries for local downloads
- **Models/** — Data structures: `ShowMetadataModel`, `PlaybackState`, `CollectionConfig`, `ShowTypes`, `ChateauGPTModel`, `SongDetailsModel`, `SearchTermsModel`, `YearsTotalResponse`
- **CarPlay/** — CarPlay scene delegate and template manager (downloads browsing)
- **Utilities/** — Shared helpers (`AppFonts`, `Utils`)

### Show Types & Multi-Source Support

The app supports three show types (see `Models/ShowTypes.swift`):
- `ShowType.archive` — Streams from archive.org (Grateful Dead, Billy Strings, Goose, etc.)
- `ShowType.downloaded` — Locally downloaded shows
- `ShowType.phishIn` — Streams from Phish.in

Collections are configured in `Models/CollectionConfig.swift`. Users can add/remove collections at runtime via `CollectionStore`. Phish uses creator-based search rather than collection-based search.

### Data Flow

1. `ArchiveAPI` / `PhishInAPI` / `PhishNetAPI` fetch show/track metadata from their respective sources
2. `AudioPlayerArchive` queues and plays tracks (streaming URLs or local files)
3. `PlayerViewModel` observes `AudioPlayerArchive` via Notifications (`.playbackStarted`, `.playbackPaused`, `.playbackStopped`) and KVO, publishing state to SwiftUI
4. SwiftUI views subscribe to `PlayerViewModel` via `@EnvironmentObject`

### Persistence

- Playback state is saved on app background and restored on next launch
- Downloaded shows are stored in SQLite via GRDB (`downloads` table)
- Deep linking supported via `chateauarchive://` URL scheme
- User-added collections persisted in UserDefaults

### Dependencies (CocoaPods)

- **Alamofire** — networking
- **SwiftyJSON** — JSON parsing
- **Signals** — event handling
- **GRDB.swift ~6.0** — SQLite ORM
