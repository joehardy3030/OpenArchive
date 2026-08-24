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
        .toolbar {
            if viewModel.isLoading {
                ToolbarItem(placement: .topBarTrailing) {
                    ProgressView()
                }
            }
        }
        .overlay {
            if viewModel.loadFailed && viewModel.shows.isEmpty && viewModel.phishInDates.isEmpty {
                ContentUnavailableView {
                    Label("Couldn't Load Shows", systemImage: "wifi.exclamationmark")
                } description: {
                    Text("archive.org didn't respond. It may be busy.")
                } actions: {
                    Button("Retry") { viewModel.retry() }
                }
            }
        }
        // Note: the navigationDestination for ShowDestination is declared once,
        // at the stack root in CollectionsView — declaring it again here is
        // ignored by SwiftUI and logs a runtime warning.
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

/// Small capsule badge for the sniffed recording type (SBD/AUD/MTX/FM).
struct RecordingTypeBadge: View {
    let type: String

    private var color: Color {
        switch type {
        case "SBD": return .blue
        case "MTX": return .purple
        case "FM": return .orange
        default: return .secondary
        }
    }

    var body: some View {
        Text(type)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

/// A single row showing artist, date, venue, source info, and ratings.
struct ShowRowView: View {
    let show: ShowMetadata

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(show.displayCreator ?? show.collection?.joined(separator: ", ") ?? "")
                .font(.system(size: 18, weight: .bold))
            HStack(spacing: 8) {
                Text(formatDate(show.date))
                    .font(.system(size: 17, weight: .bold))
                if let type = show.recordingType {
                    RecordingTypeBadge(type: type)
                }
            }
            if let loc = show.displayVenueLine {
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
            if let transferer = show.transferer, !transferer.isEmpty {
                Text(transferer)
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
            if let likes = summary?.likes_count, likes > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption2)
                    Text("\(likes)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
