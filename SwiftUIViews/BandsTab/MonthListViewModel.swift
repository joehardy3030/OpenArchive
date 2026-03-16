import Foundation

struct MonthRow: Identifiable {
    let id: Int
    let monthIndex: Int   // 1-based
    let name: String
    var count: Int
}

final class MonthListViewModel: ObservableObject {
    @Published var monthRows: [MonthRow] = []
    @Published var isLoading = false
    @Published var sbdOnly: Bool

    private let year: Int
    private let collection: String
    private let archiveAPI = ArchiveAPI()
    private var allShowsForYear: [ShowMetadata] = []
    /// Phish.in show summaries for the year, keyed by date
    private(set) var phishInShowsByDate: [String: PhishInShowSummary] = [:]

    private static let monthNames = [
        "Jan", "Feb", "Mar", "April", "May", "June",
        "July", "Aug", "Sept", "Oct", "Nov", "Dec"
    ]

    init(year: Int, collection: String) {
        self.year = year
        self.collection = collection
        self.sbdOnly = (collection == "GratefulDead")
    }

    func fetchShows() {
        isLoading = true
        let url = archiveAPI.dateRangeYearURL(year: year, sbdOnly: sbdOnly, collection: collection)
        archiveAPI.getIARequestItemsDecodable(url: url) { [weak self] (response: ShowMetadatas?, error: Error?) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                let shows = response?.items ?? []
                self.allShowsForYear = shows

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
        }

        // Fetch Phish.in show summaries once for the whole year
        if collection == "Phish" {
            PhishInAPI.shared.fetchShows(year: year) { [weak self] shows, _ in
                DispatchQueue.main.async {
                    guard let self = self, let shows = shows else { return }
                    for show in shows {
                        if let date = show.date {
                            self.phishInShowsByDate[date] = show
                        }
                    }
                }
            }
        }
    }

    func showsForMonth(_ monthIndex: Int) -> [ShowMetadata] {
        allShowsForYear.filter { show in
            guard let monthStr = show.month?.split(separator: "-").last,
                  let m = Int(monthStr) else { return false }
            return m == monthIndex
        }
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
