import Foundation

enum ShowFilter: Int, CaseIterable {
    case all = 0
    case sbd = 1
    case joesPicks = 2
}

struct MonthRow: Identifiable {
    let id: Int
    let monthIndex: Int   // 1-based
    let name: String
    var count: Int
}

final class MonthListViewModel: ObservableObject {
    @Published var monthRows: [MonthRow] = []
    @Published var isLoading = false
    @Published var filter: ShowFilter {
        didSet {
            if isGratefulDead { Self.lastGDFilter = filter }
        }
    }

    /// Remembers the last-used filter for Grateful Dead across year changes
    private static var lastGDFilter: ShowFilter = .joesPicks

    /// Exposes sbdOnly for API calls and downstream use
    var sbdOnly: Bool { filter == .sbd || filter == .joesPicks }

    let isGratefulDead: Bool
    /// Whether this collection uses the stream_only flag (drives the All/SBD picker)
    let supportsSBD: Bool

    private let year: Int
    private let collection: String
    private let archiveAPI = ArchiveAPI()
    private var allShowsForYear: [ShowMetadata] = []
    /// Phish.in show summaries for the year, keyed by date
    @Published private(set) var phishInShowsByDate: [String: PhishInShowSummary] = [:]
    /// Track pending fetches so isLoading stays true until all complete
    private var pendingFetches = 0

    private static let monthNames = [
        "Jan", "Feb", "Mar", "April", "May", "June",
        "July", "Aug", "Sept", "Oct", "Nov", "Dec"
    ]

    init(year: Int, collection: String) {
        self.year = year
        self.collection = collection
        self.isGratefulDead = (collection == "GratefulDead")
        self.supportsSBD = CollectionConfig.supportsSBDFilter(collection: collection)
        self.filter = (collection == "GratefulDead") ? Self.lastGDFilter : .all
    }

    func fetchShows() {
        // Render the 12 tappable month rows immediately — the network only
        // supplies the tape counts. A tapped month with no prefetched data
        // fetches its own single-month query in ShowsListViewModel.
        if monthRows.isEmpty { rebuildMonthRows() }
        isLoading = true
        pendingFetches = collection == "Phish" ? 2 : 1

        let url = archiveAPI.dateRangeYearURL(year: year, sbdOnly: sbdOnly, collection: collection)
        // Cache-first: this completion can fire twice (cached copy, then a
        // network diff), so the pendingFetches decrement is guarded.
        archiveAPI.getIARequestItemsCached(url: url) { [weak self] (response: ShowMetadatas?, error: Error?) in
            DispatchQueue.main.async {
                guard let self = self else { return }

                let shows = response?.items ?? []
                self.allShowsForYear = shows
                self.rebuildMonthRows()

                if self.pendingFetches > 0 { self.pendingFetches -= 1 }
                if self.pendingFetches <= 0 { self.isLoading = false }
            }
        }

        // Fetch Phish.in show summaries once for the whole year (also cache-first)
        if collection == "Phish" {
            PhishInAPI.shared.fetchShows(year: year) { [weak self] shows, _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if let shows = shows {
                        for show in shows {
                            if let date = show.date {
                                self.phishInShowsByDate[date] = show
                            }
                        }
                    }
                    if self.pendingFetches > 0 { self.pendingFetches -= 1 }
                    if self.pendingFetches <= 0 { self.isLoading = false }
                }
            }
        }
    }

    /// Rebuild month rows from allShowsForYear, applying current filter
    func rebuildMonthRows() {
        let shows: [ShowMetadata]
        if filter == .joesPicks {
            shows = Self.applyJoesPicks(allShowsForYear)
        } else {
            shows = allShowsForYear
        }

        var counts = [String: Int]()
        let grouped = Dictionary(grouping: shows, by: { $0.month })
        for (apiKey, showsInMonth) in grouped {
            if let key = apiKey, let name = self.monthName(from: key) {
                counts[name] = showsInMonth.count
            }
        }

        self.monthRows = Self.monthNames.enumerated().map { idx, name in
            MonthRow(id: idx, monthIndex: idx + 1, name: name, count: counts[name] ?? 0)
        }
    }

    func showsForMonth(_ monthIndex: Int) -> [ShowMetadata] {
        let monthShows = allShowsForYear.filter { show in
            guard let monthStr = show.month?.split(separator: "-").last,
                  let m = Int(monthStr) else { return false }
            return m == monthIndex
        }
        return filter == .joesPicks ? Self.applyJoesPicks(monthShows) : monthShows
    }

    /// Joe's Picks filter: SBD shows with avg_rating >= 4.5, num_reviews >= 2, one per date.
    /// Prefers the show with highest rating among those with 10+ reviews; falls back to highest with 2+.
    static func applyJoesPicks(_ shows: [ShowMetadata]) -> [ShowMetadata] {
        let qualifying = shows.filter { show in
            guard let rating = show.avg_rating, let reviews = show.num_reviews else { return false }
            return rating >= 4.5 && reviews >= 2
        }

        let grouped = Dictionary(grouping: qualifying) { show -> String in
            String((show.date ?? "").prefix(10))
        }

        return grouped.values.compactMap { dateShows -> ShowMetadata? in
            // Prefer shows with 10+ reviews
            let tenPlus = dateShows.filter { ($0.num_reviews ?? 0) >= 10 }
            let candidates = tenPlus.isEmpty ? dateShows : tenPlus
            return candidates.max(by: {
                let r0 = $0.avg_rating ?? 0, r1 = $1.avg_rating ?? 0
                if r0 != r1 { return r0 < r1 }
                return ($0.num_reviews ?? 0) < ($1.num_reviews ?? 0)
            })
        }
        .sorted { ($0.date ?? "") < ($1.date ?? "") }
    }

    func phishInShowsForMonth(_ monthIndex: Int) -> [String: PhishInShowSummary] {
        let monthStr = monthIndex < 10 ? "0\(monthIndex)" : "\(monthIndex)"
        let prefix = "\(year)-\(monthStr)"
        return phishInShowsByDate.filter { $0.key.hasPrefix(prefix) }
    }

    private func monthName(from monthString: String) -> String? {
        let parts = monthString.split(separator: "-")
        if let last = parts.last, let idx = Int(last), idx >= 1, idx <= 12 {
            return Self.monthNames[idx - 1]
        }
        return nil
    }
}
