# Chateau Archive

An iOS music player for streaming and downloading live concert recordings from archive.org, Phish.in, and more.

## Supported Artists

Default collections include Grateful Dead, Phish, Phil Lesh and Friends, The Other Ones, Furthur, Dead and Company, Billy Strings, Goose, and The Radiators. Users can add or remove collections at runtime.

## Features

- **Stream** live recordings from archive.org and Phish.in
- **Download** shows for offline playback
- **Browse** by band, year, month, or search across collections
- **Phish metadata** — setlists, ratings, and venues via Phish.net
- **Full player** with track list, skip, rewind, fast-forward, and scrubbing
- **Mini player** bar persists across tabs while audio is playing
- **CarPlay** support for browsing downloaded shows
- **Deep links** via `chateauarchive://` URL scheme
- **Playback persistence** — resumes where you left off after app restart

## Build

Requires Xcode and CocoaPods.

```bash
pod install
open Breaze.xcworkspace
```

Build and run targeting iOS 13.0+. Always use the `.xcworkspace`, not `.xcodeproj`.

## Architecture

SwiftUI app with a 3-tab layout (Bands, My Tapes, Search). Audio playback is handled by `AudioPlayerArchive` (AVQueuePlayer-based), with `PlayerViewModel` bridging playback state to SwiftUI. Local downloads are persisted via GRDB (SQLite).

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
