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

    // MARK: - Browse data cache
    // Both browse lists are expensive (etree: one 50k-row request; taperssection
    // artists: three 10k-row scrape pages), so they're kept for the session and
    // persisted with a TTL to survive relaunches.

    private struct CachedBrowseList<T: Codable>: Codable {
        let savedAt: Date
        let items: [T]
    }

    private static let browseCacheTTL: TimeInterval = 7 * 24 * 60 * 60

    private func loadBrowseCache<T: Codable>(key: String) -> [T]? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let cached = try? JSONDecoder().decode(CachedBrowseList<T>.self, from: data),
              Date().timeIntervalSince(cached.savedAt) < Self.browseCacheTTL else { return nil }
        return cached.items
    }

    private func saveBrowseCache<T: Codable>(_ items: [T], key: String) {
        if let data = try? JSONEncoder().encode(CachedBrowseList(savedAt: Date(), items: items)) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func fetchTapersSectionArtists() {
        guard browseArtists.isEmpty, !isArtistsLoading else { return }
        if let cached: [ArchiveAPI.ArchiveCreator] = loadBrowseCache(key: "browseArtistsCache") {
            browseArtists = cached
            return
        }
        isArtistsLoading = true
        archiveAPI.fetchCreators(inCollection: "taperssection") { [weak self] creators, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isArtistsLoading = false
                // Skip one-off uploads so the list stays browsable
                let artists = (creators ?? []).filter { $0.count >= 2 }
                self.browseArtists = artists
                if !artists.isEmpty {
                    self.saveBrowseCache(artists, key: "browseArtistsCache")
                }
            }
        }
    }

    func fetchBrowseCollections() {
        guard browseCollections.isEmpty, !isBrowseLoading else { return }
        if let cached: [ArchiveAPI.ArchiveCollection] = loadBrowseCache(key: "browseCollectionsCache") {
            browseCollections = cached
            return
        }
        isBrowseLoading = true
        archiveAPI.fetchEtreeCollections { [weak self] collections, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isBrowseLoading = false
                if let collections = collections {
                    let sorted = collections.sorted {
                        let a = ($0.title ?? $0.identifier) ?? ""
                        let b = ($1.title ?? $1.identifier) ?? ""
                        return a.localizedCaseInsensitiveCompare(b) == .orderedAscending
                    }
                    self.browseCollections = sorted
                    if !sorted.isEmpty {
                        self.saveBrowseCache(sorted, key: "browseCollectionsCache")
                    }
                }
            }
        }
    }
}
