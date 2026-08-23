import SwiftUI
import Combine

/// Keyboard overlap height for manual avoidance (the root shell opts out of
/// SwiftUI's — see ArchiveRootView). Derived from keyboard *frame geometry*
/// rather than show/hide booleans: iOS fires spurious frame-change
/// notifications with no keyboard present (after share sheets, tab switches),
/// and a frame sitting off-screen simply computes to zero overlap, so nothing
/// can get stuck.
final class KeyboardObserver: ObservableObject {
    @Published var height: CGFloat = 0
    private var cancellables = Set<AnyCancellable>()

    init() {
        let center = NotificationCenter.default
        center.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .merge(with: center.publisher(for: UIResponder.keyboardWillHideNotification))
            .sink { [weak self] note in
                guard let self else { return }
                if note.name == UIResponder.keyboardWillHideNotification {
                    self.height = 0
                    return
                }
                guard let end = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
                self.height = max(0, UIScreen.main.bounds.height - end.minY)
            }
            .store(in: &cancellables)
    }
}

/// Value-typed destination for the results page. The whole Search stack is
/// value-based on one NavigationPath — mixing navigationDestination(isPresented:)
/// with value pushes makes SwiftUI pop back to the results page when a result
/// is tapped.
struct SearchResultsDestination: Hashable {
    let title: String
}

// Note: SearchView deliberately does NOT observe PlayerViewModel — it publishes
// on a 0.5s timer during playback, and re-rendering the form at that rate makes
// open picker menus flicker. Only views that render playback state may observe it.
struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @StateObject private var keyboard = KeyboardObserver()
    @FocusState private var focusedField: Bool
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { geo in
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
            }
            .formStyle(.grouped)
            .scrollDismissesKeyboard(.interactively)
            .onSubmit { submitSearch() }
            // Manual keyboard avoidance: keyboard overlap beyond the tab-bar inset
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: max(0, keyboard.height - geo.safeAreaInsets.bottom))
            }
            .animation(.easeOut(duration: 0.25), value: keyboard.height)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: submitSearch) {
                        Label("Search", systemImage: "magnifyingglass")
                            .labelStyle(.titleAndIcon)
                            .font(.system(size: 15, weight: .bold))
                    }
                    .buttonStyle(.borderedProminent)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = false }
                }
            }
            .onAppear { viewModel.loadCollections() }
            .navigationTitle("Search")
            .navigationDestination(for: SearchResultsDestination.self) { dest in
                SearchResultsView(viewModel: viewModel, title: dest.title)
            }
            .navigationDestination(for: ShowDestination.self) { dest in
                ShowDetailView(metadata: dest.metadata, showType: dest.showType)
            }
        }
    }

    private func submitSearch() {
        focusedField = false
        viewModel.search()
        let term = viewModel.searchTerm.trimmingCharacters(in: .whitespaces)
        path.append(SearchResultsDestination(title: term.isEmpty ? "Results" : term))
    }
}

/// Full-page search results, pushed when a search is submitted.
struct SearchResultsView: View {
    @ObservedObject var viewModel: SearchViewModel
    let title: String
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
        .navigationTitle(title)
    }
}
