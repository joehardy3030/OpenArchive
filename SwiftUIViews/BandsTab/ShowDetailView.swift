import SwiftUI

struct ShowDetailView: View {
    let metadata: ShowMetadata
    let showType: ShowType

    @StateObject private var viewModel: ShowDetailViewModel
    @EnvironmentObject private var playerViewModel: PlayerViewModel
    @State private var isNotesExpanded = false

    init(metadata: ShowMetadata, showType: ShowType, existingModel: ShowMetadataModel? = nil) {
        self.metadata = metadata
        self.showType = showType
        _viewModel = StateObject(wrappedValue: ShowDetailViewModel(metadata: metadata, showType: showType, existingModel: existingModel))
    }

    var body: some View {
        List {
            // MARK: - Info Section
            Section {
                if let band = viewModel.fullMetadata?.creator ?? viewModel.fullMetadata?.collection?.first {
                    InfoRow(label: "Band", value: band)
                }
                if let date = viewModel.fullMetadata?.date { InfoRow(label: "Date", value: date) }
                if let venue = viewModel.fullMetadata?.venue { InfoRow(label: "Venue", value: venue) }
                if let coverage = viewModel.fullMetadata?.coverage { InfoRow(label: "Location", value: coverage) }
                if let src = viewModel.fullMetadata?.source, !src.isEmpty {
                    InfoRow(label: "Source", value: src.joined(separator: "; "))
                }
            }

            // MARK: - Notes Section
            Section {
                Button(isNotesExpanded ? "Hide Notes" : "Notes") {
                    withAnimation { isNotesExpanded.toggle() }
                }
                .font(.system(size: 17, weight: .bold))
                if isNotesExpanded, let desc = viewModel.fullMetadata?.description {
                    Text(desc.strippingHTML())
                        .font(.system(size: 16))
                }
            }

            // MARK: - Actions Section
            Section {
                HStack {
                    Button {
                        viewModel.streamOrPlay(startingAt: 0, playerViewModel: playerViewModel)
                    } label: {
                        Label(showType == .archive ? "Stream" : "Play",
                              systemImage: showType == .archive ? "dot.radiowaves.left.and.right" : "play.fill")
                    }
                    .frame(maxWidth: .infinity)

                    if showType == .archive {
                        Divider()
                        Button {
                            viewModel.downloadShow()
                        } label: {
                            if viewModel.isDownloading {
                                Image(systemName: "arrow.down.circle")
                                    .foregroundColor(.secondary)
                            } else if viewModel.isDownloaded {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.secondary)
                            } else {
                                Image(systemName: "arrow.down.circle")
                            }
                        }
                        .disabled(viewModel.isDownloading || viewModel.isDownloaded)
                        .frame(maxWidth: .infinity)
                        Divider()
                    }

                    ShareLink(item: viewModel.shareURL) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderless)
                .padding(.vertical, 4)
            }

            // MARK: - Tracks Section
            if let tracks = viewModel.model?.mp3Array, !tracks.isEmpty {
                Section("Tracks") {
                    ForEach(Array(tracks.enumerated()), id: \.offset) { index, track in
                        Button {
                            viewModel.streamOrPlay(startingAt: index, playerViewModel: playerViewModel)
                        } label: {
                            HStack {
                                Text(track.title ?? track.name ?? "Track \(index + 1)")
                                    .font(.system(size: 18))
                                    .foregroundColor(.primary)
                                Spacer()
                                if viewModel.pendingTrackIndex == index {
                                    ProgressView()
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(viewModel.title)
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading show...")
            }
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 16))
        }
    }
}

// Minimal HTML stripping helper
private extension String {
    func strippingHTML() -> String {
        guard let data = self.data(using: .utf8),
              let attr = try? NSAttributedString(data: data,
                  options: [.documentType: NSAttributedString.DocumentType.html,
                            .characterEncoding: String.Encoding.utf8.rawValue],
                  documentAttributes: nil)
        else { return self }
        return attr.string
    }
}
