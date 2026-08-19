# AGENTS.md

This file provides guidance to Codex and other AI agents when working with code in this repository.

## Project Overview

**Chateau Archive** is an iOS music player app for streaming and downloading live concert recordings. It supports Grateful Dead (via archive.org), Phish (via Phish.in audio + Phish.net metadata), and many other jam bands and collections from archive.org.

Naming history: the project began life in 2018 as a weather app called **Breaze** (later UpCog), which is why the workspace, Xcode target, and several file headers still say "Breaze". The product that actually builds is **Chateau.app** (bundle id `com.carquinez.chateau`), and unit tests use `@testable import Chateau`. A few weather-era remnants survive in the tree — see "Legacy & Vestigial Files" below.

## Build & Run

- Always open `Breaze.xcworkspace` (not `Breaze.xcodeproj`) — CocoaPods requires the workspace.
- Install or update dependencies: `pod install`
- Deployment target is **iOS 18.0** (all targets). The Podfile still pins pods to iOS 13.0, which is fine — only the app target's 18.0 matters for API availability.
- Build number: `Scripts/increment_build_number.sh` sets `CFBundleVersion` to the git commit count (`git rev-list --count HEAD`) at build time.
- No lint command is configured.

## Testing

`BreazeTests/BreazeTests.swift` is a real unit test suite (~80 tests) run via Xcode (Cmd+U) or `xcodebuild test -workspace Breaze.xcworkspace -scheme Breaze`. It covers:

- `ArchiveAPI` URL construction (date ranges, leap years, SBD flag, creator- vs collection-based queries, search URLs)
- `AudioPlayerArchive.normalizedStartIndex`
- `CollectionConfig` display-name/identifier mapping
- `ShowMetadata` decoding (string-or-array fields: description, collection, source)
- `PlaybackState` (show type mapping, staleness, Codable round-trip)
- `SongDetailsModel`, `Utils` (timers, dates, track URLs, path-traversal rejection)
- Joe's Picks filtering (`MonthListViewModel.applyJoesPicks`)
- `DeepLinkRouter` URL handling

`BreazeUITests/` is an untouched Xcode template — no real UI tests.

## Architecture

The app uses **SwiftUI** throughout. The UIKit-to-SwiftUI migration is complete (CarPlay necessarily uses the UIKit-style `CPTemplate` API).

### Entry Point & Navigation

```
ChateauArchiveApp (@main) → AppDelegate (audio session, notifications permission, background URLSession events, CarPlay scene routing)
                          → PlayerViewModel.shared (global playback state)
                          → DeepLinkRouter (chateauarchive:// URL handling + in-app navigation staging)
                          → ArchiveRootView (4-tab SwiftUI nav: Bands, Favorites, Downloads, Search)
```

`ArchiveRootView` also owns the global **MiniPlayerBar** (shown above the tab bar whenever a show is loaded, hidden while the keyboard is up) and presents **FullPlayerView** as a sheet. A `miniPlayerInset` EnvironmentKey pads scrolling lists so content isn't hidden behind the mini player.

Bands tab browse hierarchy: `CollectionsView` (bands) → `YearListView` → `MonthListView` → `ShowsListView` → `ShowDetailView`. Month/show lists pass prefetched data down via `NavigationStack` destination values to avoid refetching.

### Key Singletons

| Singleton | Role |
|-----------|------|
| `PlayerViewModel.shared` | Observable bridge between audio engine and SwiftUI UI |
| `AudioPlayerArchive.shared` | Core AVQueuePlayer-based playback engine |
| `LocalDatabase.shared` | GRDB SQLite database (`breaze.sqlite` in Application Support; downloads, favorites, legacy share tables) |
| `BackgroundDownloadManager.shared` | Hybrid URLSession downloader (foreground + background sessions) |
| `FavoritesStore.shared` | Favorites table access (show metadata + show type) |
| `PhishInAPI.shared` / `PhishNetAPI.shared` | Phish.in / Phish.net API clients |

### Layer Breakdown

- **SwiftUIViews/** — All SwiftUI feature views, organized by tab (`BandsTab/`, `FavoritesTab/`, `DownloadsTab/`, `SearchTab/`, `Player/`), plus `DeepLinkRouter` and `SwiftUIExtensions` (Hashable/Identifiable conformances for navigation)
- **Breaze/** — App target root: entry point, AppDelegate, ArchiveRootView, PlayerViewModel, CarPlaySceneDelegate, Info.plist
- **Network/ArchiveAPI.swift** — archive.org API calls (search/scrape queries, metadata fetching, download URLs, MP3 download validation, etree collection discovery, creator-based detection, year-range inference)
- **Network/BackgroundDownloadManager.swift** — Hybrid track downloader: default URLSession while the app is active (fast), background URLSession when suspended (survives backgrounding); validates HTTP status and file contents, reports per-track progress
- **Network/PhishInAPI.swift** — Phish.in API v2 client for Phish audience recordings (no API key required)
- **Network/PhishNetAPI.swift** — Phish.net API v5 client for Phish setlists, ratings, venues (API key in `PhishNetAPIKeys.plist`, gitignored; features silently disabled if the plist is absent)
- **Network/NetworkUtility.swift** — Download record CRUD (`downloads` table) and downloaded-show deletion
- **MediaPlayers/AudioPlayerArchive.swift** — AVQueuePlayer, remote command center, Now Playing info + artwork, audio-session interruption handling, background audio, playback state persistence, failure recovery (see below)
- **Database/LocalDatabase.swift** — GRDB schema/migrations
- **Database/FavoritesStore.swift** — GRDB `favorites` table (show metadata + show type)
- **Models/** — Data structures: `ShowMetadataModel`, `PlaybackState`, `CollectionConfig` (+ `CollectionStore`), `ShowTypes`, `SongDetailsModel`, `SearchTermsModel`, `YearsTotalResponse`, `ChateauGPTModel` (unused)
- **CarPlay/** — CarPlay template manager and downloads player (see CarPlay section)
- **Utilities/** — `AppFonts` (text styles), `Utils` (track file paths, missing-track/fully-downloaded checks, timer/date formatting; also retains unused weather-era helpers)

### Show Types & Multi-Source Support

The app supports three show types (see `Models/ShowTypes.swift`):
- `ShowType.archive` — Streams from archive.org (Grateful Dead, Billy Strings, Goose, etc.)
- `ShowType.downloaded` — Locally downloaded shows
- `ShowType.phishIn` — Streams from Phish.in

Collections are configured in `Models/CollectionConfig.swift`. Users can add/remove collections at runtime via `CollectionStore` (UserDefaults-backed; defaults can be hidden, additions persisted). The Bands tab "+" button lists all child collections of archive.org's Live Music Archive (`ArchiveAPI.fetchEtreeCollections`); on add, `detectCreatorBased` decides whether the identifier is a collection or a creator (Phish-style), and `fetchCollectionYearRange` infers the year range (stored in UserDefaults key `years_<identifier>`; hardcoded fallbacks per known band in `YearListViewModel`).

Phish uses **creator-based** search (`creator:"Phish"`) rather than collection-based; extra runtime-detected creator-based identifiers live in UserDefaults key `creatorBasedCollectionsExtra`.

### Browse Filters

`MonthListView` offers a segmented filter: **All** / **SBD** (soundboard, `stream_only` collection) / **Joe's Picks** (Grateful Dead only, and the remembered default for GD). Joe's Picks = SBD shows with `avg_rating ≥ 4.5` and `num_reviews ≥ 2`, deduplicated to one show per date (preferring the highest-rated among those with 10+ reviews). Logic in `MonthListViewModel.applyJoesPicks`.

### Data Flow

1. `ArchiveAPI` / `PhishInAPI` / `PhishNetAPI` fetch show/track metadata from their respective sources
2. `AudioPlayerArchive` queues and plays tracks (streaming URLs or local files)
3. `PlayerViewModel` observes `AudioPlayerArchive` via Notifications (`.playbackStarted`, `.playbackPaused`, `.playbackStopped`) and a periodic time observer, publishing state to SwiftUI
4. SwiftUI views subscribe to `PlayerViewModel` via `@EnvironmentObject`

### Playback Engine Details

- Track order is derived in `ShowDetailViewModel.sortKey` from filename conventions (`d1t01`/`s2t05`, `1-03_`, leading `01_`), falling back to the metadata track number.
- `AudioPlayerArchive.resolveTrackURL` prefers the local file when it exists on disk, else the archive.org streaming URL — so a partially downloaded show plays local tracks offline and streams the rest.
- Failure recovery: when a **local** item fails (corrupt/truncated file), the path is added to `pathsToForceStream` (per-show, in-session), the queue is rebuilt from the current track using the streaming URL for the bad file, and a silent re-download repairs the disk copy. When a **streaming** item fails, up to 3 consecutive failures are skipped before going idle.
- System integration: `MPRemoteCommandCenter` (play/pause/next/previous), `MPNowPlayingInfoCenter` with downloaded cover art (`setArtworkURL`, falls back to app icon), and audio-session interruption handling with auto-resume.

### Downloads

- `ShowDetailViewModel` downloads a show's tracks sequentially through `BackgroundDownloadManager`, which routes each task to a default URLSession while the app is active and a background URLSession when suspended (downloads survive backgrounding; AppDelegate forwards `handleEventsForBackgroundURLSession`, and `prepare()` at launch cancels stale background tasks).
- Each track gets up to 3 attempts with exponential backoff, and every downloaded file is validated (`ArchiveAPI.validateDownloadedMP3`: HTTP status, minimum size, Content-Length match, MP3 magic bytes) — invalid files are deleted and retried. After the chain finishes, failed tracks get one more sweep.
- The show record is saved to the `downloads` table even if some tracks failed. The Downloads tab (`DownloadsViewModel`) flags incomplete shows ("N tracks missing") with a Repair button that redownloads only the missing files — it never silently deletes records.
- A blue checkmark indicates a fully downloaded show consistently across the show detail page, Downloads rows, and Favorites rows. Tapping it offers to delete the downloaded files (via `NetworkUtility.deleteDownloadedShow`), after which the show can be downloaded fresh.
- Track filenames may contain nested paths; destination paths are sanitized against traversal (`Utils.trackURLfromName`, `BackgroundDownloadManager.destinationURL`) and files land in the app's Documents directory.

### Phish Integration

- Any show whose creator/collection is Phish gets **Phish.net** enrichment in `ShowDetailViewModel`: setlist grouped by set (with jamchart stars and setlist notes), venue/location/tour name. Attribution ("Data courtesy of Phish.net / The Mockingbird Foundation") is required and rendered under the setlist.
- **Phish.in** shows (`phishin-YYYY-MM-DD` identifiers) stream directly from `mp3_url`s; soundcheck tracks are filtered out; per-track jamchart flags/notes and like counts are displayed; cover art comes from Phish.in.
- In the Bands tab, the Phish month/show lists merge both sources: a "Phish.in Recordings" section (audience recordings, one per date) above the "Archive.org Recordings" section, with archive rows enriched with Phish.in venue data when missing.

### CarPlay

- `AppDelegate` routes the CarPlay scene (declared in Info.plist) to `CarPlaySceneDelegate`, which creates `CarPlayTemplateManager`.
- The CarPlay UI is a single "My Tapes" `CPListTemplate` of fully downloaded shows (incomplete ones filtered out), paginated 10 per page with See more / Show previous rows.
- Selecting a show hands off to `CarPlayDownloadsTemplate`, which plays it through `AudioPlayerArchive` and maintains Now Playing info. (A decade/year browse flow exists in the code but is currently disabled.)

### Persistence

- Playback state is saved on app background/termination and on every track change; restored on next launch (paused, seeked to the saved position). Stored as JSON in UserDefaults key `lastPlaybackState`; discarded when older than 7 days (`PlaybackState.isStale`).
- Downloaded shows are stored in SQLite via GRDB (`downloads` table: identifier + JSON-encoded `ShowMetadataModel`); DB file is `breaze.sqlite` in Application Support. A `share` table exists in the schema but is legacy/unused.
- Favorites are stored in SQLite via GRDB (`favorites` table: identifier, JSON model, showType, created_at), independent of downloads.
- Deep linking: `chateauarchive://<identifier>` opens the show detail (identifiers prefixed `phishin-` route as Phish.in shows). `DeepLinkRouter` also stages in-app navigation from the full player's info button (fires after the sheet dismisses).
- User-added collections, hidden defaults, creator-based extras, and inferred year ranges are persisted in UserDefaults.

### Legacy & Vestigial Files

Files on disk that are **not** part of the build (not referenced by the Xcode target) or are dead code — don't extend them; they're candidates for cleanup:

- Root-level `FavoritesView.swift` / `FavoritesViewModel.swift` — stale older copies; the compiled versions live in `SwiftUIViews/FavoritesTab/`.
- `city.list.json`, weather helpers in `Utils.swift` (conditions/temperature/wind), location-usage strings in Info.plist — weather-app leftovers.
- `Models/ChateauGPTModel.swift` — compiled but referenced by nothing (abandoned GPT experiment).
- `share` table in `LocalDatabase` — created by migration, never used.
- `Breaze 2023-01-29 20-25-48/` — an old App Store export artifact (ipa + plists).
- `BreazeTests` in the Podfile inherits search paths; `BreazeUITests` is an empty template.

### Dependencies (CocoaPods)

- **Alamofire** — networking (ArchiveAPI, Phish clients; downloads themselves use raw URLSession in `BackgroundDownloadManager`)
- **SwiftyJSON** — JSON parsing (legacy; new code uses Codable)
- **Signals** — event handling (legacy)
- **GRDB.swift ~6.0** — SQLite ORM
