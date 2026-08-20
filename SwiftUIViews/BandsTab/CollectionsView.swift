import SwiftUI

struct CollectionsView: View {
    @StateObject private var viewModel = CollectionsViewModel()
    @EnvironmentObject private var deepLinkRouter: DeepLinkRouter
    @Environment(\.miniPlayerInset) private var miniPlayerInset
    @State private var showBrowseSheet = false
    @State private var showRemoveSheet = false
    @State private var deepLinkPath = NavigationPath()
    @State private var deepLinkModel: ShowMetadataModel? = nil

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
            .padding(.bottom, miniPlayerInset)
            .navigationTitle("Bands")
            .navigationDestination(for: CollectionEntry.self) { entry in
                YearListView(collection: entry.identifier, title: entry.displayName)
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: { showRemoveSheet = true }) {
                        Image(systemName: "minus")
                    }
                    Button(action: {
                        viewModel.fetchBrowseCollections()
                        viewModel.fetchTapersSectionArtists()
                        showBrowseSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: ShowDestination.self) { dest in
                ShowDetailView(metadata: dest.metadata, showType: dest.showType, existingModel: deepLinkModel)
                    .onAppear { deepLinkModel = nil }
            }
            .onReceive(deepLinkRouter.$pendingShow) { show in
                guard show != nil else { return }
                guard let (metadata, showType, model) = deepLinkRouter.consume() else { return }
                deepLinkModel = model
                deepLinkPath.append(ShowDestination(metadata: metadata, showType: showType))
            }
            .sheet(isPresented: $showRemoveSheet) {
                RemoveBandsSheet(entries: viewModel.entries) { entry in
                    viewModel.remove(entry)
                }
            }
            .sheet(isPresented: $showBrowseSheet) {
                BrowseCollectionsSheet(
                    collections: viewModel.browseCollections,
                    artists: viewModel.browseArtists,
                    isLoading: viewModel.isBrowseLoading,
                    isArtistsLoading: viewModel.isArtistsLoading,
                    onSelect: { selected in
                        let title = (selected.title ?? selected.identifier) ?? "Unknown"
                        let id = selected.identifier ?? title
                        viewModel.addAndInferYears(displayName: title, identifier: id)
                        showBrowseSheet = false
                    },
                    onSelectArtist: { artist in
                        // Creator-based add (the Phish pattern): finds the artist's
                        // tapes across all collections, not just taperssection
                        viewModel.addAndInferYears(displayName: artist.name, identifier: artist.name)
                        showBrowseSheet = false
                    }
                )
            }
        }
    }
}

// MARK: - Remove Bands Sheet

struct RemoveBandsSheet: View {
    let entries: [CollectionEntry]
    let onRemove: (CollectionEntry) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(entries, id: \.identifier) { entry in
                    Button(role: .destructive) {
                        onRemove(entry)
                    } label: {
                        HStack {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                            Text(entry.displayName)
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                }
            }
            .navigationTitle("Remove Bands")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Browse Collections Sheet

struct BrowseCollectionsSheet: View {
    let collections: [ArchiveAPI.ArchiveCollection]
    var artists: [ArchiveAPI.ArchiveCreator] = []
    let isLoading: Bool
    var isArtistsLoading: Bool = false
    let onSelect: (ArchiveAPI.ArchiveCollection) -> Void
    var onSelectArtist: (ArchiveAPI.ArchiveCreator) -> Void = { _ in }

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

    private var filteredArtists: [ArchiveAPI.ArchiveCreator] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return artists
        }
        let q = searchText.lowercased()
        return artists.filter { $0.name.lowercased().contains(q) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading bands...")
                } else {
                    List {
                        Section("Live Music Archive") {
                            ForEach(filtered, id: \.identifier) { item in
                                Button {
                                    onSelect(item)
                                } label: {
                                    Text((item.title ?? item.identifier) ?? "Unknown")
                                        .font(.system(size: 18, weight: .bold))
                                }
                            }
                        }
                        Section("Taper's Section Artists") {
                            if isArtistsLoading {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text("Loading artists...")
                                        .foregroundColor(.secondary)
                                }
                            }
                            ForEach(filteredArtists, id: \.name) { artist in
                                Button {
                                    onSelectArtist(artist)
                                } label: {
                                    HStack {
                                        Text(artist.name)
                                            .font(.system(size: 18, weight: .bold))
                                        Spacer()
                                        Text("\(artist.count) tapes")
                                            .font(.system(size: 15))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
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
