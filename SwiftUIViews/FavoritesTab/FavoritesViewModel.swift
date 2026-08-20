import Foundation

final class FavoritesViewModel: ObservableObject {
    @Published var favorites: [(show: ShowMetadataModel, showType: ShowType)] = []
    @Published var isLoading = false
    /// Identifiers of favorites that are fully downloaded (all track files on disk).
    @Published var downloadedIDs: Set<String> = []

    private let network = NetworkUtility()
    private let utils = Utils()

    func loadFavorites() {
        isLoading = true
        FavoritesStore.shared.getAllFavorites { [weak self] results in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                self.favorites = results
            }
        }
        refreshDownloadedStatus()
    }

    func removeFavorite(at index: Int) {
        guard index < favorites.count else { return }
        let identifier = favorites[index].show.metadata?.identifier
        if let identifier {
            FavoritesStore.shared.removeFavorite(identifier: identifier)
        }
        favorites.remove(at: index)
    }

    /// Deletes the downloaded copy of a favorite (files + record). The favorite
    /// itself is kept; only the local download goes away.
    func deleteDownload(for show: ShowMetadataModel) {
        guard let identifier = show.metadata?.identifier else { return }
        network.deleteDownloadedShow(identifier: identifier) { [weak self] in
            self?.downloadedIDs.remove(identifier)
        }
    }

    private func refreshDownloadedStatus() {
        network.getAllDownloadDocs(decade: nil) { [weak self] shows in
            // Per-track file checks off the main thread — they contend with
            // active download writes and stall the Favorites list otherwise.
            DispatchQueue.global(qos: .userInitiated).async {
                guard let self, let shows else { return }
                var ids = Set<String>()
                for show in shows {
                    if let id = show.metadata?.identifier,
                       self.utils.isShowFullyDownloaded(show) {
                        ids.insert(id)
                    }
                }
                DispatchQueue.main.async {
                    self.downloadedIDs = ids
                }
            }
        }
    }
}
