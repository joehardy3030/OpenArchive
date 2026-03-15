import Foundation

final class SearchViewModel: ObservableObject {
    @Published var searchTerm = ""
    @Published var venue = ""
    @Published var startYear = ""
    @Published var endYear = ""
    @Published var minRating = ""
    @Published var selectedCollectionIndex = 0
    @Published var results: [ShowMetadata]? = nil
    @Published var isLoading = false
    @Published var collectionEntries: [CollectionEntry] = []

    private let archiveAPI = ArchiveAPI()
    private let store = CollectionStore()

    var collectionDisplayNames: [String] {
        collectionEntries.map { $0.displayName }
    }

    var collectionIdentifiers: [String] {
        collectionEntries.map { $0.identifier }
    }

    func loadCollections() {
        collectionEntries = store.getEntries()
        if selectedCollectionIndex >= collectionEntries.count {
            selectedCollectionIndex = 0
        }
    }

    func search() {
        let model = SearchTermsModel(
            searchTerm: searchTerm.isEmpty ? nil : searchTerm,
            venue: venue.isEmpty ? nil : venue,
            startYear: startYear.isEmpty ? nil : startYear,
            endYear: endYear.isEmpty ? nil : endYear,
            minRating: minRating.isEmpty ? nil : minRating,
            sbdOnly: nil,
            collection: collectionIdentifiers[selectedCollectionIndex]
        )

        isLoading = true
        let url = archiveAPI.searchTermURL(
            searchTerm: model.searchTerm,
            venue: model.venue,
            minRating: model.minRating,
            startYear: model.startYear,
            endYear: model.endYear,
            sbdOnly: model.sbdOnly,
            collection: model.collection
        )

        archiveAPI.getIARequestItemsDecodable(url: url) { [weak self] (response: ShowMetadatas?, error: Error?) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                if let items = response?.items, !items.isEmpty {
                    self.results = items.sorted { ($0.date ?? "") < ($1.date ?? "") }
                } else {
                    self.results = []
                }
            }
        }
    }
}
