import SwiftUI

struct DownloadsView: View {
    @StateObject private var viewModel = DownloadsViewModel()
    @Environment(\.miniPlayerInset) private var miniPlayerInset

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.shows, id: \.metadata?.identifier) { show in
                    NavigationLink(value: DownloadedShowDestination(model: show)) {
                        DownloadedShowRow(show: show)
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        viewModel.deleteShow(at: index)
                    }
                }
            }
            .padding(.bottom, miniPlayerInset)
            .navigationTitle("My Tapes")
            .navigationDestination(for: DownloadedShowDestination.self) { dest in
                ShowDetailView(metadata: dest.model.metadata ?? ShowMetadata(identifier: "unknown"),
                               showType: .downloaded,
                               existingModel: dest.model)
            }
            .onAppear {
                viewModel.loadDownloads()
            }
            .overlay {
                if viewModel.shows.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView("No Downloads",
                                          systemImage: "arrow.down.circle",
                                          description: Text("Shows you download will appear here."))
                }
            }
        }
    }
}

struct DownloadedShowDestination: Hashable {
    let model: ShowMetadataModel

    func hash(into hasher: inout Hasher) {
        hasher.combine(model.metadata?.identifier)
    }

    static func == (lhs: DownloadedShowDestination, rhs: DownloadedShowDestination) -> Bool {
        lhs.model.metadata?.identifier == rhs.model.metadata?.identifier
    }
}

struct DownloadedShowRow: View {
    let show: ShowMetadataModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(show.metadata?.creator ?? show.metadata?.collection?.joined(separator: ", ") ?? "")
                .font(.system(size: 18, weight: .bold))
            Text(formatDate(show.metadata?.date))
                .font(.system(size: 17, weight: .bold))
            if let venue = show.metadata?.venue {
                let loc = [venue, show.metadata?.coverage].compactMap { $0 }.joined(separator: ", ")
                Text(loc)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            if let src = show.metadata?.source, !src.isEmpty {
                Text(src.joined(separator: "; "))
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            if let rating = show.metadata?.avg_rating, let reviews = show.metadata?.num_reviews {
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
