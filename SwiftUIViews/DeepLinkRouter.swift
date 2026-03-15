import SwiftUI

/// Coordinates deep link navigation from custom URL scheme (chateauarchive://<identifier>).
final class DeepLinkRouter: ObservableObject {
    @Published var pendingShow: ShowMetadata? = nil

    func handle(url: URL) {
        guard let identifier = url.host, !identifier.isEmpty else { return }
        pendingShow = ShowMetadata(identifier: identifier)
    }

    func consume() -> ShowMetadata? {
        defer { pendingShow = nil }
        return pendingShow
    }
}
