import SwiftUI

struct ShowsListView: View {
    let year: Int
    let month: Int
    let collection: String
    let filter: ShowFilter
    let prefetchedShows: [ShowMetadata]
    let prefetchedPhishIn: [String: PhishInShowSummary]

    @Environment(\.miniPlayerInset) private var miniPlayerInset
    @StateObject private var viewModel: ShowsListViewModel

    init(year: Int, month: Int, collection: String, filter: ShowFilter,
         prefetchedShows: [ShowMetadata], prefetchedPhishIn: [String: PhishInShowSummary] = [:]) {
        self.year = year
        self.month = month
        self.collection = collection
        self.filter = filter
        self.prefetchedShows = prefetchedShows
        self.prefetchedPhishIn = prefetchedPhishIn
        _viewModel = StateObject(wrappedValue: ShowsListViewModel(
            year: year, month: month, collection: collection,
            filter: filter, prefetchedShows: prefetchedShows,
            prefetchedPhishIn: prefetchedPhishIn
        ))
    }

    var body: some View {
        List {
            // Phish.in recordings (shown first for Phish collection)
            if !viewModel.phishInDates.isEmpty {
                Section("Phish.in Recordings") {
                    ForEach(viewModel.phishInDates.sorted(), id: \.self) { date in
                        let meta = viewModel.phishInMetadata(for: date)
                        NavigationLink(value: ShowDestination(metadata: meta, showType: .phishIn)) {
                            PhishInRowView(date: date, summary: viewModel.phishInShowsByDate[date])
                        }
                    }
                }
            }

            // Archive.org recordings
            Section(viewModel.phishInDates.isEmpty ? "" : "Archive.org Recordings") {
                ForEach(viewModel.shows, id: \.identifier) { show in
                    NavigationLink(value: ShowDestination(metadata: show, showType: .archive)) {
                        ShowRowView(show: show)
                    }
                }
            }
        }
        .padding(.bottom, miniPlayerInset)
        .navigationTitle(viewModel.navigationTitle)
        .navigationDestination(for: ShowDestination.self) { dest in
            ShowDetailView(metadata: dest.metadata, showType: dest.showType)
        }
    }
}

struct ShowDestination: Hashable {
    let metadata: ShowMetadata
    let showType: ShowType

    func hash(into hasher: inout Hasher) {
        hasher.combine(metadata.identifier)
        hasher.combine(String(describing: showType))
    }

    static func == (lhs: ShowDestination, rhs: ShowDestination) -> Bool {
        lhs.metadata.identifier == rhs.metadata.identifier && lhs.showType == rhs.showType
    }
}

/// A single row showing artist, date, venue, source info, and ratings.
struct ShowRowView: View {
    let show: ShowMetadata

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(show.creator ?? show.collection?.joined(separator: ", ") ?? "")
                .font(.system(size: 18, weight: .bold))
            Text(formatDate(show.date))
                .font(.system(size: 17, weight: .bold))
            if let venue = show.venue {
                let loc = [venue, show.coverage].compactMap { $0 }.joined(separator: ", ")
                Text(loc)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            if let src = show.source, !src.isEmpty {
                Text(src.joined(separator: "; "))
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            if let rating = show.avg_rating, let reviews = show.num_reviews {
                Text("\(String(format: "%.1f", rating)) stars  \(reviews) ratings")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ dateString: String?) -> String {
        guard let dateString else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }
        return dateString
    }
}

/// Row for a Phish.in recording entry.
struct PhishInRowView: View {
    let date: String
    let summary: PhishInShowSummary?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Phish")
                .font(.system(size: 18, weight: .bold))
            Text(date)
                .font(.system(size: 17, weight: .bold))
            if let venue = summary?.venue_name ?? summary?.venue?.name {
                let loc = [venue, summary?.venue?.location].compactMap { $0 }.joined(separator: ", ")
                Text(loc)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
