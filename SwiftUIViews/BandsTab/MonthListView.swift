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
            Picker("Source", selection: $viewModel.sbdOnly) {
                Text("All").tag(false)
                Text("SBD").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .onChange(of: viewModel.sbdOnly) { viewModel.fetchShows() }

            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                List(viewModel.monthRows) { row in
                    NavigationLink(value: MonthDestination(
                        monthIndex: row.monthIndex,
                        year: year,
                        collection: collection,
                        sbdOnly: viewModel.sbdOnly,
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
        }
        .navigationTitle("Months")
        .navigationDestination(for: MonthDestination.self) { dest in
            ShowsListView(
                year: dest.year,
                month: dest.monthIndex,
                collection: dest.collection,
                sbdOnly: dest.sbdOnly,
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
    let sbdOnly: Bool
    let prefetchedShows: [ShowMetadata]
    let prefetchedPhishIn: [String: PhishInShowSummary]

    func hash(into hasher: inout Hasher) {
        hasher.combine(monthIndex)
        hasher.combine(year)
        hasher.combine(collection)
        hasher.combine(sbdOnly)
    }

    static func == (lhs: MonthDestination, rhs: MonthDestination) -> Bool {
        lhs.monthIndex == rhs.monthIndex && lhs.year == rhs.year &&
        lhs.collection == rhs.collection && lhs.sbdOnly == rhs.sbdOnly
    }
}
