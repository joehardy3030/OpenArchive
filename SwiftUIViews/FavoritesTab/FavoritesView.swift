import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel = FavoritesViewModel()
    @Environment(\.miniPlayerInset) private var miniPlayerInset

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(viewModel.favorites.enumerated()), id: \.element.show.metadata?.identifier) { index, fav in
                    NavigationLink(value: FavoriteShowDestination(model: fav.show, showType: fav.showType)) {
                        FavoriteShowRow(show: fav.show)
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        viewModel.removeFavorite(at: index)
                    }
                }
            }
            .padding(.bottom, miniPlayerInset)
            .navigationTitle("Favorites")
            .navigationDestination(for: FavoriteShowDestination.self) { dest in
                ShowDetailView(metadata: dest.model.metadata ?? ShowMetadata(identifier: "unknown"),
                               showType: dest.showType,
                               existingModel: dest.showType == .downloaded ? dest.model : nil)
            }
            .onAppear {
                viewModel.loadFavorites()
            }
            .overlay {
                if viewModel.favorites.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView("No Favorites",
                                          systemImage: "star",
                                          description: Text("Tap the star on any show to add it to your favorites."))
                }
            }
        }
    }
}

struct FavoriteShowDestination: Hashable {
    let model: ShowMetadataModel
    let showType: ShowType

    func hash(into hasher: inout Hasher) {
        hasher.combine(model.metadata?.identifier)
    }

    static func == (lhs: FavoriteShowDestination, rhs: FavoriteShowDestination) -> Bool {
        lhs.model.metadata?.identifier == rhs.model.metadata?.identifier
    }
}

struct FavoriteShowRow: View {
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
            if let transferer = show.metadata?.transferer, !transferer.isEmpty {
                Text(transferer)
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
