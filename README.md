# Chateau Archive

An iOS music player for streaming and downloading live concert recordings from archive.org, Phish.in, and more.

## Supported Artists

Default collections include Grateful Dead, Phish, Jerry Garcia, Phil Lesh and Friends, The Other Ones, Furthur, Dead and Company, Billy Strings, Goose, and The Radiators. Users can add or remove bands at runtime.

## Features

- **Stream** live recordings from archive.org and Phish.in
- **Download** shows for offline playback — downloads continue in the background while the app is suspended, with per-track progress and validation
- **Download repair** — incomplete downloads are flagged and can be repaired by fetching only the missing tracks; a consistent blue check marks fully downloaded shows and lets you delete/redownload them
- **Favorites** — star any show and browse favorites in their own tab
- **Browse** by band, year, month, or search across collections
- **Phish metadata** — setlists, ratings, and venues via Phish.net
- **Full player** with track list, skip, rewind, fast-forward, and scrubbing
- **Mini player** bar persists across tabs while audio is playing
- **Joe's Picks** — curated Grateful Dead filter: top-rated soundboards, one per show date
- **Add any band** — browse archive.org's Live Music Archive collections or Taper's Section artists and add them at runtime
- **CarPlay** support for browsing and playing downloaded shows
- **Deep links** via `chateauarchive://` URL scheme
- **Playback persistence** — resumes where you left off after app restart

## Build

Requires Xcode and CocoaPods.

```bash
pod install
open Breaze.xcworkspace
```

Build and run targeting iOS 18.0+. Always use the `.xcworkspace`, not `.xcodeproj`. The workspace and target are named "Breaze" for historical reasons; the app builds as **Chateau**.

Unit tests live in `BreazeTests/` (run with Cmd+U in Xcode).

## Architecture

SwiftUI app with a 4-tab layout (Bands, Favorites, Downloads, Search). Audio playback is handled by `AudioPlayerArchive` (AVQueuePlayer-based), with `PlayerViewModel` bridging playback state to SwiftUI. Downloads run through a hybrid `BackgroundDownloadManager` (fast foreground URLSession, background URLSession when suspended). Local downloads and favorites are persisted via GRDB (SQLite).

See [CLAUDE.md](CLAUDE.md) for detailed architecture documentation.

## Dependencies

- [Alamofire](https://github.com/Alamofire/Alamofire) — networking
- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) — JSON parsing
- [Signals](https://github.com/artman/Signals) — event handling
- [GRDB.swift](https://github.com/groue/GRDB.swift) — SQLite ORM

## Credits

- Live recordings from [archive.org](https://archive.org)
- Phish audio from [Phish.in](https://phish.in)
- Phish metadata courtesy of [Phish.net](https://phish.net) / The Mockingbird Foundation
