import Foundation

final class FavoritesViewModel: ObservableObject {
    @Published var favorites: [(show: ShowMetadataModel, showType: ShowType)] = []
    @Published var isLoading = false

    func loadFavorites() {
        isLoading = true
        FavoritesStore.shared.getAllFavorites { [weak self] results in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                self.favorites = results
            }
        }
    }

    func removeFavorite(at index: Int) {
        guard index < favorites.count else { return }
        let identifier = favorites[index].show.metadata?.identifier
        if let identifier {
            FavoritesStore.shared.removeFavorite(identifier: identifier)
        }
        favorites.remove(at: index)
    }
}
