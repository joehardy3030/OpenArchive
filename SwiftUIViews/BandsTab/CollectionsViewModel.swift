import Foundation

final class CollectionsViewModel: ObservableObject {
    @Published var entries: [CollectionEntry] = []
    @Published var browseCollections: [ArchiveAPI.ArchiveCollection] = []
    @Published var isBrowseLoading = false
    /// Artists inside taperssection, addable as creator-based bands
    @Published var browseArtists: [ArchiveAPI.ArchiveCreator] = []
    @Published var isArtistsLoading = false

    private let store = CollectionStore()
    private let archiveAPI = ArchiveAPI()

    init() {
        entries = store.getEntries()
    }

    func reload() {
        entries = store.getEntries()
    }

    func remove(_ entry: CollectionEntry) {
        store.removeCollection(entry)
        reload()
    }

    func addAndInferYears(displayName: String, identifier: String) {
        archiveAPI.detectCreatorBased(collectionOrCreator: identifier) { [weak self] isCreator in
            if isCreator {
                let defaults = UserDefaults.standard
                var extra = defaults.stringArray(forKey: "creatorBasedCollectionsExtra") ?? []
                if !extra.contains(identifier) {
                    extra.append(identifier)
                    defaults.set(extra, forKey: "creatorBasedCollectionsExtra")
                }
            }
            self?.archiveAPI.fetchCollectionYearRange(identifier: identifier, isCreatorBased: isCreator) { range in
                if let (minY, maxY) = range {
                    UserDefaults.standard.set([minY, maxY], forKey: "years_\(identifier)")
                }
                DispatchQueue.main.async {
                    self?.store.addCollection(displayName: displayName, identifier: identifier)
                    self?.reload()
                }
            }
        }
    }

    func fetchTapersSectionArtists() {
        guard browseArtists.isEmpty, !isArtistsLoading else { return }
        isArtistsLoading = true
        archiveAPI.fetchCreators(inCollection: "taperssection") { [weak self] creators, _ in
            DispatchQueue.main.async {
                self?.isArtistsLoading = false
                // Skip one-off uploads so the list stays browsable
                self?.browseArtists = (creators ?? []).filter { $0.count >= 2 }
            }
        }
    }

    func fetchBrowseCollections() {
        isBrowseLoading = true
        archiveAPI.fetchEtreeCollections { [weak self] collections, error in
            DispatchQueue.main.async {
                self?.isBrowseLoading = false
                if let collections = collections {
                    self?.browseCollections = collections.sorted {
                        let a = ($0.title ?? $0.identifier) ?? ""
                        let b = ($1.title ?? $1.identifier) ?? ""
                        return a.localizedCaseInsensitiveCompare(b) == .orderedAscending
                    }
                }
            }
        }
    }
}
