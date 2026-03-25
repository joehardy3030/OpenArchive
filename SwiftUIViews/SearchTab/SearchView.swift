import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject private var playerViewModel: PlayerViewModel
    @Environment(\.miniPlayerInset) private var miniPlayerInset
    @FocusState private var focusedField: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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
                    }
                    Section {
                        Button("Search") {
                            viewModel.search()
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

                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }

                if let results = viewModel.results {
                    if results.isEmpty {
                        ContentUnavailableView.search
                    } else {
                        List(results, id: \.identifier) { show in
                            NavigationLink(value: ShowDestination(metadata: show, showType: .archive)) {
                                ShowRowView(show: show)
                            }
                        }
                        .padding(.bottom, miniPlayerInset)
                    }
                }
            }
            .onAppear { viewModel.loadCollections() }
            .navigationTitle("Search")
            .navigationDestination(for: ShowDestination.self) { dest in
                ShowDetailView(metadata: dest.metadata, showType: dest.showType)
            }
        }
    }
}
