import Foundation

final class ShowsListViewModel: ObservableObject {
    @Published var shows: [ShowMetadata] = []
    /// Phish.in show dates available for this month (only for Phish collection)
    @Published var phishInDates: Set<String> = []
    /// Full Phish.in show summaries keyed by date
    private(set) var phishInShowsByDate: [String: PhishInShowSummary] = [:]

    let year: Int
    let month: Int
    let collection: String

    private let archiveAPI = ArchiveAPI()

    var navigationTitle: String {
        let months = ["Jan","Feb","Mar","April","May","June","July","Aug","Sept","Oct","Nov","Dec"]
        if month >= 1, month <= 12 {
            return "\(months[month - 1]) \(year)"
        }
        return "\(year)"
    }

    init(year: Int, month: Int, collection: String, sbdOnly: Bool, prefetchedShows: [ShowMetadata]) {
        self.year = year
        self.month = month
        self.collection = collection

        if !prefetchedShows.isEmpty {
            self.shows = prefetchedShows.sorted { ($0.date ?? "") < ($1.date ?? "") }
        } else {
            fetchFromAPI(sbdOnly: sbdOnly)
        }

        // Fetch Phish.in show dates for Phish collection
        if collection == "Phish" {
            fetchPhishInDates()
        }
    }

    private func fetchFromAPI(sbdOnly: Bool) {
        let url = archiveAPI.dateRangeURL(year: year, month: month, sbdOnly: sbdOnly, collection: collection)
        archiveAPI.getIARequestItemsDecodable(url: url) { [weak self] (response: ShowMetadatas?, error: Error?) in
            DispatchQueue.main.async {
                if let items = response?.items, !items.isEmpty {
                    self?.shows = items.sorted { ($0.date ?? "") < ($1.date ?? "") }
                }
            }
        }
    }

    private func fetchPhishInDates() {
        PhishInAPI.shared.fetchShows(year: year) { [weak self] shows, _ in
            DispatchQueue.main.async {
                guard let self = self, let shows = shows else { return }
                let monthStr = self.month < 10 ? "0\(self.month)" : "\(self.month)"
                let prefix = "\(self.year)-\(monthStr)"
                let filtered = shows.filter { ($0.date ?? "").hasPrefix(prefix) }
                self.phishInDates = Set(filtered.compactMap { $0.date })
                for show in filtered {
                    if let date = show.date {
                        self.phishInShowsByDate[date] = show
                    }
                }
            }
        }
    }

    /// Check if a given show date has a Phish.in recording
    func hasPhishInRecording(date: String?) -> Bool {
        guard let date = date else { return false }
        let showDate = String(date.prefix(10))
        return phishInDates.contains(showDate)
    }

    /// Create a ShowMetadata stub for a Phish.in recording on a given date
    func phishInMetadata(for date: String) -> ShowMetadata {
        var meta = ShowMetadata(identifier: "phishin-\(date)")
        meta.date = "\(date)T00:00:00Z"
        meta.creator = "Phish"
        meta.source = ["Phish.in audience recording"]
        if let summary = phishInShowsByDate[date] {
            meta.venue = summary.venue_name ?? summary.venue?.name
            meta.coverage = summary.venue?.location
        }
        return meta
    }
}
