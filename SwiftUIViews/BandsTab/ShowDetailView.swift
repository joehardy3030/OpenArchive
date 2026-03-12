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
            // MARK: - Actions Section
            Section {
                HStack(spacing: 20) {
                    Button {
                        viewModel.streamOrPlay(startingAt: 0, playerViewModel: playerViewModel)
                    } label: {
                        let isStreaming = showType == .archive && !viewModel.isDownloaded
                        Label(isStreaming ? "Stream" : "Play",
                              systemImage: isStreaming ? "dot.radiowaves.left.and.right" : "play.fill")
                            .lineLimit(1)
                    }

                    Spacer()

                    if showType == .archive {
                        Button {
                            viewModel.downloadShow(playerViewModel: playerViewModel)
                        } label: {
                            if viewModel.isDownloading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if viewModel.isDownloaded {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            } else {
                                Image(systemName: "arrow.down.circle")
                            }
                        }
                        .disabled(viewModel.isDownloading || viewModel.isDownloaded)
                    }

                    ShareLink(item: viewModel.shareURL) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .buttonStyle(.borderless)
                .padding(.vertical, 4)
            }

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
                if isNotesExpanded {
                    if let desc = viewModel.fullMetadata?.description {
                        Text(desc.strippingHTML())
                            .font(.system(size: 16))
                    } else {
                        Text("No notes available")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }

            // MARK: - Tracks Section
            if let tracks = viewModel.model?.mp3Array, !tracks.isEmpty {
                Section("Tracks") {
                    ForEach(Array(tracks.enumerated()), id: \.offset) { index, track in
                        Button {
                            viewModel.streamOrPlay(startingAt: index, playerViewModel: playerViewModel)
                        } label: {
                            HStack {
                                let isCurrentShow = playerViewModel.currentShow?.metadata?.identifier == metadata.identifier
                                let isCurrentTrack = isCurrentShow && playerViewModel.currentTrackIndex == index
                                if isCurrentTrack {
                                    Image(systemName: playerViewModel.isPlaying ? "speaker.wave.2.fill" : "speaker.fill")
                                        .foregroundColor(.accentColor)
                                        .frame(width: 24)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                }
                                Text(track.title ?? track.name ?? "Track \(index + 1)")
                                    .font(.system(size: 18))
                                    .foregroundColor(.primary)
                                Spacer()
                                if viewModel.pendingTrackIndex == index {
                                    ProgressView()
                                } else if viewModel.downloadingTrackIndex == index {
                                    ProgressView()
                                        .tint(.blue)
                                } else if track.destination != nil {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .foregroundColor(.accentColor)
                                        .font(.caption)
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
        self.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
