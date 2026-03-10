import Foundation

final class ShowsListViewModel: ObservableObject {
    @Published var shows: [ShowMetadata] = []

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
}
