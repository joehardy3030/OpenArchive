import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject private var playerViewModel: PlayerViewModel
    @FocusState private var focusedField: Bool
    @State private var showResults = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Search term", text: $viewModel.searchTerm)
                    TextField("Venue", text: $viewModel.venue)
                }
                Section {
                    TextField("Start Year (YYYY)", text: $viewModel.startYear)
                        .keyboardType(.numberPad)
                        .focused($focusedField)
                    TextField("End Year (YYYY)", text: $viewModel.endYear)
                        .keyboardType(.numberPad)
                        .focused($focusedField)
                    TextField("Min Rating (1-5)", text: $viewModel.minRating)
                        .keyboardType(.decimalPad)
                        .focused($focusedField)
                }
                Section {
                    Picker("Band", selection: $viewModel.selectedCollectionIndex) {
                        ForEach(0..<viewModel.collectionDisplayNames.count, id: \.self) { i in
                            Text(viewModel.collectionDisplayNames[i]).tag(i)
                        }
                    }
                    Picker("Recording Type", selection: $viewModel.recordingTypeFilter) {
                        Text("Any").tag("")
                        Text("SBD").tag("SBD")
                        Text("AUD").tag("AUD")
                        Text("MTX").tag("MTX")
                        Text("FM").tag("FM")
                    }
                }
                Section {
                    Button("Search") {
                        focusedField = false
                        viewModel.search()
                        showResults = true
                    }
                    .frame(maxWidth: .infinity)
                    .font(.system(size: 17, weight: .bold))
                }
            }
            .formStyle(.grouped)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = false }
                }
            }
            .onAppear { viewModel.loadCollections() }
            .navigationTitle("Search")
            .navigationDestination(isPresented: $showResults) {
                SearchResultsView(viewModel: viewModel)
            }
            .navigationDestination(for: ShowDestination.self) { dest in
                ShowDetailView(metadata: dest.metadata, showType: dest.showType)
            }
        }
    }
}

/// Full-page search results, pushed when a search is submitted.
struct SearchResultsView: View {
    @ObservedObject var viewModel: SearchViewModel
    @Environment(\.miniPlayerInset) private var miniPlayerInset

    var body: some View {
        Group {
            if viewModel.results != nil {
                let shown = viewModel.filteredResults
                if shown.isEmpty {
                    ContentUnavailableView.search
                } else {
                    List(shown, id: \.identifier) { show in
                        NavigationLink(value: ShowDestination(metadata: show, showType: .archive)) {
                            ShowRowView(show: show)
                        }
                    }
                    .padding(.bottom, miniPlayerInset)
                }
            } else if viewModel.isLoading {
                ProgressView("Searching...")
            } else {
                ContentUnavailableView.search
            }
        }
        .navigationTitle(viewModel.recordingTypeFilter.isEmpty
                         ? "Results"
                         : "\(viewModel.recordingTypeFilter) Results")
    }
}
