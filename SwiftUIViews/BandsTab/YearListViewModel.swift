import Foundation

final class YearListViewModel: ObservableObject {
    @Published var years: [Int] = []
    @Published var yearTotals: [Int: Int] = [:]

    private let collection: String

    init(collection: String) {
        self.collection = collection
        self.years = Self.buildYears(for: collection)
    }

    private static func buildYears(for collection: String) -> [Int] {
        if let stored = UserDefaults.standard.array(forKey: "years_\(collection)") as? [Int],
           stored.count == 2, stored[0] <= stored[1] {
            return Array(stored[0]...stored[1])
        }
        switch collection {
        case "GratefulDead": return Array(1965...1995)
        case "BillyStrings": return Array(2015...2026)
        case "PhilLeshandFriends": return Array(1996...2026)
        case "GooseBand": return Array(2017...2026)
        case "Furthur": return Array(2009...2014)
        case "TheOtherOnes": return Array(1998...2002)
        case "DeadAndCompany": return Array(2015...2026)
        case "Radiators": return Array(1983...2026)
        case "Phish": return Array(1990...2026)
        default: return Array(1965...1995)
        }
    }
}
