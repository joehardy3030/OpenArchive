import SwiftUI

struct MonthListView: View {
    let year: Int
    let collection: String

    @Environment(\.miniPlayerInset) private var miniPlayerInset
    @StateObject private var viewModel: MonthListViewModel

    init(year: Int, collection: String) {
        self.year = year
        self.collection = collection
        _viewModel = StateObject(wrappedValue: MonthListViewModel(year: year, collection: collection))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.supportsSBD {
                Picker("Source", selection: $viewModel.filter) {
                    Text("All").tag(ShowFilter.all)
                    Text("SBD").tag(ShowFilter.sbd)
                    if viewModel.isGratefulDead {
                        Text("Joe's Picks").tag(ShowFilter.joesPicks)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .onChange(of: viewModel.filter) { oldValue, newValue in
                    // SBD and Joe's Picks use the same API data (sbdOnly=true).
                    // Only refetch if sbdOnly actually changed.
                    let wasSbd = (oldValue == .sbd || oldValue == .joesPicks)
                    let isSbd = (newValue == .sbd || newValue == .joesPicks)
                    if wasSbd != isSbd {
                        viewModel.fetchShows()
                    } else {
                        viewModel.rebuildMonthRows()
                    }
                }
            }

            List(viewModel.monthRows) { row in
                NavigationLink(value: MonthDestination(
                    monthIndex: row.monthIndex,
                    year: year,
                    collection: collection,
                    filter: viewModel.filter,
                    prefetchedShows: viewModel.showsForMonth(row.monthIndex),
                    prefetchedPhishIn: viewModel.phishInShowsForMonth(row.monthIndex)
                )) {
                    if row.count > 0 {
                        Text("\(row.name) \(String(year)) (\(row.count) tapes)")
                            .font(.system(size: 18))
                    } else {
                        Text("\(row.name) \(String(year))")
                            .font(.system(size: 18))
                    }
                }
            }
            .padding(.bottom, miniPlayerInset)
        }
        .navigationTitle("Months")
        .toolbar {
            if viewModel.isLoading {
                ToolbarItem(placement: .topBarTrailing) {
                    ProgressView()
                }
            }
        }
        .navigationDestination(for: MonthDestination.self) { dest in
            ShowsListView(
                year: dest.year,
                month: dest.monthIndex,
                collection: dest.collection,
                filter: dest.filter,
                prefetchedShows: dest.prefetchedShows,
                prefetchedPhishIn: dest.prefetchedPhishIn
            )
        }
        .onAppear {
            if viewModel.monthRows.isEmpty { viewModel.fetchShows() }
        }
    }
}

struct MonthDestination: Hashable {
    let monthIndex: Int
    let year: Int
    let collection: String
    let filter: ShowFilter
    let prefetchedShows: [ShowMetadata]
    let prefetchedPhishIn: [String: PhishInShowSummary]

    func hash(into hasher: inout Hasher) {
        hasher.combine(monthIndex)
        hasher.combine(year)
        hasher.combine(collection)
        hasher.combine(filter)
    }

    static func == (lhs: MonthDestination, rhs: MonthDestination) -> Bool {
        lhs.monthIndex == rhs.monthIndex && lhs.year == rhs.year &&
        lhs.collection == rhs.collection && lhs.filter == rhs.filter
    }
}
