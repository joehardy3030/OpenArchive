import SwiftUI

/// Coordinates deep link navigation from custom URL scheme (chateauarchive://<identifier>)
/// and in-app navigation (e.g. info button on the full player).
final class DeepLinkRouter: ObservableObject {
    @Published var pendingShow: ShowMetadata? = nil
    @Published var pendingShowType: ShowType = .archive

    func handle(url: URL) {
        guard let identifier = url.host, !identifier.isEmpty else { return }
        pendingShowType = .archive
        pendingShow = ShowMetadata(identifier: identifier)
    }

    func navigate(to metadata: ShowMetadata, showType: ShowType) {
        pendingShowType = showType
        pendingShow = metadata
    }

    func consume() -> (ShowMetadata, ShowType)? {
        defer { pendingShow = nil; pendingShowType = .archive }
        guard let show = pendingShow else { return nil }
        return (show, pendingShowType)
    }
}
