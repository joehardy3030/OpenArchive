import Foundation

final class DownloadsViewModel: ObservableObject {
    @Published var shows: [ShowMetadataModel] = []
    @Published var isLoading = false
    /// Missing track names keyed by show identifier, for shows with an
    /// incomplete download on disk.
    @Published var missingTracks: [String: [String]] = [:]
    /// Identifiers of shows currently being repaired (redownloading missing tracks).
    @Published var repairingShowIDs: Set<String> = []

    private let network = NetworkUtility()
    private let archiveAPI = ArchiveAPI()
    private let utils = Utils()

    func loadDownloads() {
        isLoading = true
        network.getAllDownloadDocs(decade: nil) { [weak self] response in
            // Scan disk off the main thread: this is one file check per track per
            // show, and the checks contend with active download writes.
            DispatchQueue.global(qos: .userInitiated).async {
                guard let self = self else { return }
                let downloadedShows = response ?? []

                // Flag shows with tracks missing on disk so they can be repaired,
                // rather than hiding them and deleting their records.
                var missing: [String: [String]] = [:]
                for show in downloadedShows {
                    guard let id = show.metadata?.identifier else { continue }
                    let names = self.missingTrackNames(for: show)
                    if !names.isEmpty {
                        missing[id] = names
                    }
                }

                // Sort by date
                let sorted = downloadedShows.sorted { s1, s2 in
                    guard let d1 = s1.metadata?.date,
                          let date1 = self.utils.getDateFromDateString(datetime: d1) else { return false }
                    guard let d2 = s2.metadata?.date,
                          let date2 = self.utils.getDateFromDateString(datetime: d2) else { return true }
                    return date1 < date2
                }

                DispatchQueue.main.async {
                    self.isLoading = false
                    self.missingTracks = missing
                    self.shows = sorted
                }
            }
        }
    }

    func deleteShow(at index: Int) {
        guard index < shows.count else { return }
        let show = shows[index]
        network.deleteDownloadedShow(identifier: show.metadata?.identifier)
        if let id = show.metadata?.identifier {
            missingTracks[id] = nil
        }
        shows.remove(at: index)
    }

    func deleteShow(_ show: ShowMetadataModel) {
        guard let index = shows.firstIndex(where: {
            $0.metadata?.identifier == show.metadata?.identifier
        }) else { return }
        deleteShow(at: index)
    }

    // MARK: - Repair

    /// Redownloads the missing tracks of an incomplete show, then re-checks it.
    func repairShow(_ show: ShowMetadataModel) {
        guard let id = show.metadata?.identifier,
              let names = missingTracks[id], !names.isEmpty,
              !repairingShowIDs.contains(id) else { return }
        repairingShowIDs.insert(id)
        print("DownloadsViewModel: repairing \(id) — \(names.count) missing track(s)")
        downloadMissingTrack(names, index: 0, identifier: id)
    }

    private func downloadMissingTrack(_ names: [String], index: Int, identifier: String) {
        guard index < names.count else {
            finishRepair(identifier: identifier)
            return
        }
        let name = names[index]
        guard let url = archiveAPI.downloadURL(identifier: identifier, filename: name) else {
            downloadMissingTrack(names, index: index + 1, identifier: identifier)
            return
        }
        BackgroundDownloadManager.shared.download(from: url) { [weak self] _, error in
            if let error = error {
                print("DownloadsViewModel: repair failed for \(name): \(error.localizedDescription)")
            }
            self?.downloadMissingTrack(names, index: index + 1, identifier: identifier)
        }
    }

    private func finishRepair(identifier: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.repairingShowIDs.remove(identifier)
            if let show = self.shows.first(where: { $0.metadata?.identifier == identifier }) {
                let stillMissing = self.missingTrackNames(for: show)
                self.missingTracks[identifier] = stillMissing.isEmpty ? nil : stillMissing
                print("DownloadsViewModel: repair of \(identifier) finished — \(stillMissing.count) track(s) still missing")
            }
        }
    }

    private func missingTrackNames(for show: ShowMetadataModel) -> [String] {
        utils.missingTrackNames(for: show)
    }
}
