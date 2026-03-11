import Foundation

final class ShowDetailViewModel: ObservableObject {
    @Published var model: ShowMetadataModel?
    @Published var isLoading = false
    @Published var pendingTrackIndex: Int? = nil

    let showType: ShowType
    private let initialMetadata: ShowMetadata
    private let archiveAPI = ArchiveAPI()
    private let utils = Utils()
    private let player = AudioPlayerArchive.shared

    var fullMetadata: ShowMetadata? { model?.metadata }

    var title: String {
        utils.getDateFromDateTimeString(datetime: initialMetadata.date) ?? initialMetadata.date ?? ""
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
                self.model = showData
            }
        }
    }

    func streamOrPlay(startingAt index: Int, playerViewModel: PlayerViewModel) {
        guard let m = model else { return }
        pendingTrackIndex = index

        player.pause()
        player.showMetadataModel = m

        if showType == .archive {
            player.loadStreamingQueuePlayer(startingAt: index)
        } else if let tracks = m.mp3Array {
            player.loadQueuePlayer(tracks: tracks, startingAt: index)
        }

        player.play()
        pendingTrackIndex = nil

        // Push state into the shared view model
        playerViewModel.currentShow = m
        playerViewModel.isStreaming = (showType == .archive)
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
