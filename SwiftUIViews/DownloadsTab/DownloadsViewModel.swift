import Foundation

final class DownloadsViewModel: ObservableObject {
    @Published var shows: [ShowMetadataModel] = []
    @Published var isLoading = false

    private let network = NetworkUtility()
    private let utils = Utils()
    private let fileManager = FileManager.default

    func loadDownloads() {
        isLoading = true
        network.getAllDownloadDocs(decade: nil) { [weak self] response in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                guard var downloadedShows = response else {
                    self.shows = []
                    return
                }

                // Remove shows whose tracks no longer exist on disk
                downloadedShows = downloadedShows.filter { show in
                    if self.tracksExist(for: show) {
                        return true
                    } else {
                        self.network.removeDownloadDataDoc(docID: show.metadata?.identifier)
                        return false
                    }
                }

                // Sort by date
                self.shows = downloadedShows.sorted { s1, s2 in
                    guard let d1 = s1.metadata?.date,
                          let date1 = self.utils.getDateFromDateString(datetime: d1) else { return false }
                    guard let d2 = s2.metadata?.date,
                          let date2 = self.utils.getDateFromDateString(datetime: d2) else { return true }
                    return date1 < date2
                }
            }
        }
    }

    func deleteShow(at index: Int) {
        guard index < shows.count else { return }
        let show = shows[index]

        // Delete track files
        if let mp3s = show.mp3Array {
            for mp3 in mp3s {
                if let localURL = utils.trackURLfromName(name: mp3.name),
                   fileManager.fileExists(atPath: localURL.path) {
                    try? fileManager.removeItem(at: localURL)
                }
            }
        }

        // Remove from database
        network.removeDownloadDataDoc(docID: show.metadata?.identifier)
        shows.remove(at: index)
    }

    private func tracksExist(for show: ShowMetadataModel) -> Bool {
        guard let mp3s = show.mp3Array else { return false }
        for song in mp3s {
            guard let trackURL = utils.trackURLfromName(name: song.name),
                  (try? trackURL.checkResourceIsReachable()) == true else {
                return false
            }
        }
        return true
    }
}
