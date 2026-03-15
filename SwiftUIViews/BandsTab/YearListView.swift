import SwiftUI

struct YearListView: View {
    let collection: String
    let title: String

    @StateObject private var viewModel: YearListViewModel

    init(collection: String, title: String) {
        self.collection = collection
        self.title = title
        _viewModel = StateObject(wrappedValue: YearListViewModel(collection: collection))
    }

    var body: some View {
        List(viewModel.years, id: \.self) { year in
            NavigationLink(value: YearDestination(year: year, collection: collection)) {
                if let total = viewModel.yearTotals[year] {
                    Text(verbatim: "\(year) (\(total) tapes)")
                        .font(.system(size: 18))
                } else {
                    Text(verbatim: "\(year)")
                        .font(.system(size: 18))
                }
            }
        }
        .navigationTitle(title)
        .navigationDestination(for: YearDestination.self) { dest in
            MonthListView(year: dest.year, collection: dest.collection)
        }
    }
}

struct YearDestination: Hashable {
    let year: Int
    let collection: String
}
