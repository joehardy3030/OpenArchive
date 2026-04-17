import SwiftUI

/// Coordinates deep link navigation from custom URL scheme (chateauarchive://<identifier>)
/// and in-app navigation (e.g. info button on the full player).
final class DeepLinkRouter: ObservableObject {
    @Published var pendingShow: ShowMetadata? = nil
    @Published var pendingShowType: ShowType = .archive
    @Published var pendingModel: ShowMetadataModel? = nil

    /// Staged navigation from full player info button; fires after sheet dismisses
    var pendingNavigation: (ShowMetadata, ShowType, ShowMetadataModel?)? = nil

    func handle(url: URL) {
        guard let identifier = url.host, !identifier.isEmpty else { return }
        pendingShowType = identifier.hasPrefix("phishin-") ? .phishIn : .archive
        pendingModel = nil
        pendingShow = ShowMetadata(identifier: identifier)
    }

    func navigate(to metadata: ShowMetadata, showType: ShowType, model: ShowMetadataModel? = nil) {
        pendingShowType = showType
        pendingModel = model
        pendingShow = metadata
    }

    func consume() -> (ShowMetadata, ShowType, ShowMetadataModel?)? {
        defer { pendingShow = nil; pendingShowType = .archive; pendingModel = nil }
        guard let show = pendingShow else { return nil }
        return (show, pendingShowType, pendingModel)
    }
}
