import Foundation

// MARK: - Hashable conformances for SwiftUI navigation

extension ShowMetadata: Hashable {
    static func == (lhs: ShowMetadata, rhs: ShowMetadata) -> Bool {
        lhs.identifier == rhs.identifier
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

extension CollectionEntry: Hashable, Identifiable {
    var id: String { identifier }
    static func == (lhs: CollectionEntry, rhs: CollectionEntry) -> Bool {
        lhs.identifier == rhs.identifier
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

extension ShowType: Hashable {}

extension ArchiveAPI.ArchiveCollection: Identifiable {
    var id: String { identifier ?? UUID().uuidString }
}
