import Foundation

final class ShowDetailViewModel: ObservableObject {
    @Published var model: ShowMetadataModel?
    @Published var isLoading = false
    @Published var pendingTrackIndex: Int? = nil
    @Published var isDownloading = false
    @Published var isDownloaded = false

    // Phish.net metadata enrichment (only populated for Phish shows)
    @Published var phishNetSetlist: [SetlistSet] = []
    @Published var phishNetVenue: String?
    @Published var phishNetLocation: String?
    @Published var phishNetTourName: String?
    @Published var phishNetSetlistNotes: String?
    @Published var isPhishNetLoading = false

    let showType: ShowType
    private let initialMetadata: ShowMetadata
    private let archiveAPI = ArchiveAPI()
    private let utils = Utils()
    private let network = NetworkUtility()
    private let fileManager = FileManager.default
    private let player = AudioPlayerArchive.shared
    @Published var downloadingTrackIndex: Int? = nil
    var fullMetadata: ShowMetadata? { model?.metadata }

    /// Whether this show is a Phish show (eligible for Phish.net enrichment)
    var isPhishShow: Bool {
        if let creator = initialMetadata.creator, creator.lowercased() == "phish" { return true }
        if let colls = initialMetadata.collection, colls.contains(where: { $0.lowercased() == "phish" }) { return true }
        return false
    }

    var title: String {
        let formatted = utils.getDateFromDateTimeString(datetime: initialMetadata.date)
        if let f = formatted, !f.isEmpty { return f }
        return initialMetadata.date ?? ""
    }

    var shareURL: URL {
        utils.urlFromIdentifier(identifier: initialMetadata.identifier)
    }

    init(metadata: ShowMetadata, showType: ShowType, existingModel: ShowMetadataModel? = nil) {
        self.initialMetadata = metadata
        self.showType = showType

        if let existingModel {
            self.model = existingModel
        } else if showType == .archive {
            fetchShowDetail()
        }

        if isPhishShow {
            fetchPhishNetMetadata()
        }
    }

    private func fetchShowDetail() {
        guard let id = initialMetadata.identifier else { return }
        isLoading = true
        let url = archiveAPI.metadataURL(identifier: id)
        archiveAPI.getIARequestMetadataDecodable(url: url) { [weak self] (response: ShowMetadataModel?, error: Error?) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                guard var showData = response else { return }

                // Carry over ratings from initial shallow metadata
                if let ar = self.initialMetadata.avg_rating {
                    showData.metadata?.avg_rating = ar
                }
                if let nr = self.initialMetadata.num_reviews {
                    showData.metadata?.num_reviews = nr
                }

                // Build and sort mp3 array
                if let files = showData.files {
                    var mp3s = [ShowMP3]()
                    for f in files {
                        if (f.format?.contains("MP3")) ?? false {
                            mp3s.append(ShowMP3(identifier: self.initialMetadata.identifier,
                                                name: f.name, title: f.title, track: f.track))
                        }
                    }
                    showData.mp3Array = mp3s.sorted { self.sortKey(for: $0) < self.sortKey(for: $1) }
                }
                self.isDownloaded = showData.mp3Array?.allSatisfy { mp3 in
                    guard let name = mp3.name,
                          let localURL = self.utils.trackURLfromName(name: name) else { return false }
                    return self.fileManager.fileExists(atPath: localURL.path)
                } ?? false
                self.model = showData
            }
        }
    }

    func streamOrPlay(startingAt index: Int, playerViewModel: PlayerViewModel) {
        guard let m = model else { return }
        pendingTrackIndex = index

        player.pause()
        player.showMetadataModel = m

        let playLocally = showType == .downloaded || isDownloaded
        if playLocally, let tracks = m.mp3Array {
            player.loadQueuePlayer(tracks: tracks, startingAt: index)
        } else {
            player.loadStreamingQueuePlayer(startingAt: index)
        }

        player.play()
        pendingTrackIndex = nil

        // Push state into the shared view model
        playerViewModel.currentShow = m
        playerViewModel.isStreaming = !playLocally
    }

    // MARK: - Download

    func downloadShow(playerViewModel: PlayerViewModel) {
        guard !isDownloading, !isDownloaded else { return }
        guard let mp3s = model?.mp3Array, !mp3s.isEmpty else { return }
        isDownloading = true
        downloadingTrackIndex = 0
        self.downloadPlayerViewModel = playerViewModel
        downloadSyncRun()
    }

    private weak var downloadPlayerViewModel: PlayerViewModel?

    private func downloadSyncRun() {
        guard let mp3s = model?.mp3Array, let idx = downloadingTrackIndex else { return }
        if idx < mp3s.count {
            downloadSync(showMP3: mp3s[idx])
        } else {
            saveDownloadData()
        }
    }

    private func downloadSync(showMP3: ShowMP3) {
        downloadSong(showMP3: showMP3) { [weak self] destination in
            guard let self else { return }
            DispatchQueue.main.async {
                self.setDownloadComplete(destination: destination, name: showMP3.name)
                let justFinishedIndex = self.downloadingTrackIndex ?? 0

                // Start playing as soon as the first track finishes downloading
                if justFinishedIndex == 0, let pvm = self.downloadPlayerViewModel {
                    self.streamOrPlay(startingAt: 0, playerViewModel: pvm)
                }

                self.downloadingTrackIndex = justFinishedIndex + 1
                self.downloadSyncRun()
            }
        }
    }

    private func downloadSong(showMP3: ShowMP3, completion: @escaping (URL?) -> Void) {
        guard let trackName = showMP3.name else { completion(nil); return }
        let url = archiveAPI.downloadURL(identifier: initialMetadata.identifier, filename: trackName)
        guard let localURL = utils.trackURLfromName(name: trackName) else { completion(nil); return }

        if fileManager.fileExists(atPath: localURL.path) {
            completion(localURL)
        } else {
            archiveAPI.getIADownload(url: url) { localFileURL, error in
                guard error == nil else { return }
                completion(localFileURL)
            }
        }
    }

    private func setDownloadComplete(destination: URL?, name: String?) {
        guard let d = destination, let count = model?.mp3Array?.count else { return }
        for i in 0..<count where model?.mp3Array?[i].name == name {
            model?.mp3Array?[i].destination = d
        }
    }

    private func saveDownloadData() {
        _ = network.addDownloadDataDoc(showMetadataModel: model)
        DispatchQueue.main.async {
            self.isDownloading = false
            self.downloadingTrackIndex = nil
            self.isDownloaded = true
        }
    }

    // MARK: - Phish.net Metadata Enrichment

    private func fetchPhishNetMetadata() {
        guard let dateStr = initialMetadata.date else { return }
        // Extract YYYY-MM-DD from the date string (may include time component)
        let showDate = String(dateStr.prefix(10))
        guard showDate.count == 10 else { return }

        isPhishNetLoading = true

        PhishNetAPI.shared.fetchSetlist(date: showDate) { [weak self] response, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isPhishNetLoading = false

                guard let entries = response?.data, !entries.isEmpty else { return }

                // Group setlist entries by set name
                var setDict: [String: [SetlistSong]] = [:]
                var setOrder: [String] = []

                for entry in entries {
                    let setName = entry.set ?? "Unknown"
                    let song = SetlistSong(
                        name: entry.song ?? "Unknown",
                        position: entry.position ?? 0,
                        isJamChart: (entry.isjamchart ?? 0) == 1,
                        jamChartDescription: entry.jamchart_description
                    )
                    if setDict[setName] == nil {
                        setDict[setName] = []
                        setOrder.append(setName)
                    }
                    setDict[setName]?.append(song)
                }

                self.phishNetSetlist = setOrder.map { name in
                    SetlistSet(name: name, songs: (setDict[name] ?? []).sorted { $0.position < $1.position })
                }

                // Extract venue/location/tour from first entry
                if let first = entries.first {
                    self.phishNetVenue = first.venue
                    if let city = first.city {
                        var loc = city
                        if let state = first.state, !state.isEmpty { loc += ", \(state)" }
                        if let country = first.country, !country.isEmpty { loc += ", \(country)" }
                        self.phishNetLocation = loc
                    }
                    self.phishNetTourName = first.tourname
                    self.phishNetSetlistNotes = first.setlistnotes
                }
            }
        }
    }

    // MARK: - Sort helpers (mirrors ShowViewController logic)

    private func sortKey(for mp3: ShowMP3) -> (Int, Int, String) {
        let name = mp3.name ?? ""
        let lastComponent = URL(fileURLWithPath: name).lastPathComponent
        let fallback = mp3.title ?? lastComponent

        // d1t01 or s2t05
        if let regex = try? NSRegularExpression(pattern: "(?i)[ds](\\d+)t(\\d+)"),
           let match = regex.firstMatch(in: lastComponent, range: NSRange(location: 0, length: lastComponent.utf16.count)),
           match.numberOfRanges >= 3,
           let dr = Range(match.range(at: 1), in: lastComponent),
           let tr = Range(match.range(at: 2), in: lastComponent) {
            return (Int(lastComponent[dr]) ?? 1, Int(lastComponent[tr]) ?? 1, fallback)
        }

        // 1-03_...
        if let regex = try? NSRegularExpression(pattern: "^(\\d{1,2})-(\\d{1,2})[ _-]"),
           let match = regex.firstMatch(in: lastComponent, range: NSRange(location: 0, length: lastComponent.utf16.count)),
           match.numberOfRanges >= 3,
           let dr = Range(match.range(at: 1), in: lastComponent),
           let tr = Range(match.range(at: 2), in: lastComponent) {
            return (Int(lastComponent[dr]) ?? 1, Int(lastComponent[tr]) ?? 1, fallback)
        }

        // 01_... leading track
        if let regex = try? NSRegularExpression(pattern: "^(\\d{1,3})[ _-]"),
           let match = regex.firstMatch(in: lastComponent, range: NSRange(location: 0, length: lastComponent.utf16.count)),
           match.numberOfRanges >= 2,
           let tr = Range(match.range(at: 1), in: lastComponent) {
            return (1, Int(lastComponent[tr]) ?? 1, fallback)
        }

        var track = 9999
        if let t = mp3.track {
            let prefix = t.prefix { $0.isNumber }
            if let p = Int(prefix) { track = p }
        }
        return (1, track, fallback)
    }
}

// MARK: - Setlist Models

struct SetlistSong: Identifiable {
    let id = UUID()
    let name: String
    let position: Int
    let isJamChart: Bool
    let jamChartDescription: String?
}

struct SetlistSet: Identifiable {
    let id = UUID()
    let name: String
    let songs: [SetlistSong]
}
