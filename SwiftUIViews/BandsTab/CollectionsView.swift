import SwiftUI

struct CollectionsView: View {
    @StateObject private var viewModel = CollectionsViewModel()
    @EnvironmentObject private var deepLinkRouter: DeepLinkRouter
    @State private var showBrowseSheet = false
    @State private var deepLinkPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $deepLinkPath) {
            List {
                ForEach(viewModel.entries, id: \.identifier) { entry in
                    NavigationLink(value: entry) {
                        Text(entry.displayName)
                            .font(.system(size: 18, weight: .bold))
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        viewModel.remove(viewModel.entries[index])
                    }
                }
            }
            .navigationTitle("Bands")
            .navigationDestination(for: CollectionEntry.self) { entry in
                YearListView(collection: entry.identifier, title: entry.displayName)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { viewModel.fetchBrowseCollections(); showBrowseSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: ShowDestination.self) { dest in
                ShowDetailView(metadata: dest.metadata, showType: dest.showType)
            }
            .onReceive(deepLinkRouter.$pendingShow) { show in
                guard let show else { return }
                _ = deepLinkRouter.consume()
                deepLinkPath.append(ShowDestination(metadata: show, showType: .archive))
            }
            .sheet(isPresented: $showBrowseSheet) {
                BrowseCollectionsSheet(
                    collections: viewModel.browseCollections,
                    isLoading: viewModel.isBrowseLoading
                ) { selected in
                    let title = (selected.title ?? selected.identifier) ?? "Unknown"
                    let id = selected.identifier ?? title
                    viewModel.addAndInferYears(displayName: title, identifier: id)
                    showBrowseSheet = false
                }
            }
        }
    }
}

// MARK: - Browse Collections Sheet

struct BrowseCollectionsSheet: View {
    let collections: [ArchiveAPI.ArchiveCollection]
    let isLoading: Bool
    let onSelect: (ArchiveAPI.ArchiveCollection) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filtered: [ArchiveAPI.ArchiveCollection] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return collections
        }
        let q = searchText.lowercased()
        return collections.filter {
            let t = (($0.title ?? $0.identifier) ?? "").lowercased()
            return t.contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading bands...")
                } else {
                    List(filtered, id: \.identifier) { item in
                        Button {
                            onSelect(item)
                        } label: {
                            Text((item.title ?? item.identifier) ?? "Unknown")
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search")
                }
            }
            .navigationTitle("Browse Bands")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
