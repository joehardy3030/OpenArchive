import SwiftUI

struct ShowDetailView: View {
    let metadata: ShowMetadata
    let showType: ShowType

    @StateObject private var viewModel: ShowDetailViewModel
    @EnvironmentObject private var playerViewModel: PlayerViewModel
    @Environment(\.miniPlayerInset) private var miniPlayerInset
    @State private var isNotesExpanded = false
    @State private var isSetlistExpanded = false

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
                        let isStreaming = showType == .phishIn || (showType == .archive && !viewModel.isDownloaded)
                        Label(isStreaming ? "Stream" : "Play",
                              systemImage: isStreaming ? "dot.radiowaves.left.and.right" : "play.fill")
                            .lineLimit(1)
                    }

                    Spacer()

                    if showType == .archive {
                        Button {
                            viewModel.downloadShow()
                        } label: {
                            if viewModel.isDownloading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if viewModel.isDownloaded {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            } else if !viewModel.failedTrackNames.isEmpty {
                                Image(systemName: "exclamationmark.arrow.circlepath")
                                    .foregroundColor(.orange)
                            } else {
                                Image(systemName: "arrow.down.circle")
                            }
                        }
                        .disabled(viewModel.isDownloading || viewModel.isDownloaded)
                    }

                    Button {
                        viewModel.toggleFavorite()
                    } label: {
                        Image(systemName: viewModel.isFavorite ? "star.fill" : "star")
                            .foregroundColor(viewModel.isFavorite ? .yellow : .primary)
                    }

                    ShareLink(item: viewModel.shareURL) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .buttonStyle(.borderless)
                .padding(.vertical, 4)
            }

            // MARK: - Show Image
            if let imageURL = viewModel.showImageURL {
                Section {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(8)
                        case .failure:
                            EmptyView()
                        case .empty:
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .listRowInsets(EdgeInsets())
                }
            }

            // MARK: - Info Section
            Section {
                if let band = viewModel.fullMetadata?.creator ?? viewModel.fullMetadata?.collection?.first {
                    InfoRow(label: "Band", value: band)
                }
                if let date = viewModel.fullMetadata?.date { InfoRow(label: "Date", value: date) }
                // Prefer Phish.net venue/location when available
                if let venue = viewModel.phishNetVenue ?? viewModel.fullMetadata?.venue {
                    InfoRow(label: "Venue", value: venue)
                }
                if let location = viewModel.phishNetLocation ?? viewModel.fullMetadata?.coverage {
                    InfoRow(label: "Location", value: location)
                }
                if let src = viewModel.fullMetadata?.source, !src.isEmpty {
                    InfoRow(label: "Source", value: src.joined(separator: "; "))
                }
                if let transferer = viewModel.fullMetadata?.transferer, !transferer.isEmpty {
                    InfoRow(label: "Transferer", value: transferer)
                }
                if let rating = viewModel.fullMetadata?.avg_rating {
                    let reviews = viewModel.fullMetadata?.num_reviews ?? 0
                    InfoRow(label: "Recording Rating", value: "\(String(format: "%.1f", rating)) stars (\(reviews) reviews)")
                }
                if let tour = viewModel.phishNetTourName {
                    InfoRow(label: "Tour", value: tour)
                }
                if showType == .phishIn && viewModel.phishInShowLikes > 0 {
                    InfoRow(label: "Likes", value: "\(viewModel.phishInShowLikes)")
                }
                if let taperNotes = viewModel.phishInTaperNotes, !taperNotes.isEmpty {
                    InfoRow(label: "Taper Notes", value: taperNotes)
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

            // MARK: - Phish.net Setlist Section
            if !viewModel.phishNetSetlist.isEmpty {
                Section {
                    Button(isSetlistExpanded ? "Hide Setlist" : "Setlist") {
                        withAnimation { isSetlistExpanded.toggle() }
                    }
                    .font(.system(size: 17, weight: .bold))
                    if isSetlistExpanded {
                        ForEach(viewModel.phishNetSetlist) { set in
                            Text(setDisplayName(set.name))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                            ForEach(set.songs) { song in
                                HStack {
                                    Text(song.name)
                                        .font(.system(size: 16))
                                    if song.isJamChart {
                                        Image(systemName: "star.fill")
                                            .font(.caption2)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                        }
                        if let notes = viewModel.phishNetSetlistNotes, !notes.isEmpty {
                            Text(notes.strippingHTML())
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        Text("Data courtesy of Phish.net / The Mockingbird Foundation")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            } else if viewModel.isPhishNetLoading {
                Section {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading setlist...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }

            // MARK: - Tracks Section
            if let tracks = viewModel.model?.mp3Array, !tracks.isEmpty {
                Section("Tracks") {
                    ForEach(Array(tracks.enumerated()), id: \.offset) { index, track in
                        VStack(alignment: .leading, spacing: 4) {
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
                                    // Phish.in track indicators
                                    if showType == .phishIn, index < viewModel.phishInTracks.count {
                                        let phishTrack = viewModel.phishInTracks[index]
                                        if phishTrack.isJamchart {
                                            Image(systemName: "flame.fill")
                                                .foregroundColor(.orange)
                                                .font(.caption)
                                        }
                                        if let likes = phishTrack.likes_count, likes > 0 {
                                            HStack(spacing: 2) {
                                                Image(systemName: "heart.fill")
                                                    .foregroundColor(.red)
                                                    .font(.caption2)
                                                Text("\(likes)")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    if viewModel.pendingTrackIndex == index {
                                        ProgressView()
                                    } else if viewModel.downloadingTrackIndex == index {
                                        if viewModel.currentTrackProgress > 0 {
                                            Text("\(Int(viewModel.currentTrackProgress * 100))%")
                                                .font(.caption.monospacedDigit())
                                                .foregroundColor(.blue)
                                        } else {
                                            ProgressView()
                                                .tint(.blue)
                                        }
                                    } else if track.destination != nil {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .foregroundColor(.accentColor)
                                            .font(.caption)
                                    }
                                }
                            }
                            // Jamcharts annotation below the track
                            if showType == .phishIn, index < viewModel.phishInTracks.count,
                               let notes = viewModel.phishInTracks[index].jamchartsNotes {
                                Text(notes)
                                    .font(.system(size: 13))
                                    .foregroundColor(.orange)
                                    .padding(.leading, 28)
                            }
                        }
                    }
                }
            }
        }
        .padding(.bottom, miniPlayerInset)
        .navigationTitle(viewModel.title)
        .overlay {
            if viewModel.isLoading && viewModel.model?.metadata == nil {
                ProgressView("Loading show...")
            }
        }
        .alert("Download Incomplete",
               isPresented: Binding(
                   get: { viewModel.downloadAlertMessage != nil },
                   set: { if !$0 { viewModel.downloadAlertMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.downloadAlertMessage ?? "")
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

private func setDisplayName(_ raw: String) -> String {
    switch raw.lowercased() {
    case "1": return "Set 1"
    case "2": return "Set 2"
    case "3": return "Set 3"
    case "e": return "Encore"
    case "e2": return "Encore 2"
    default: return raw
    }
}

// Minimal HTML stripping helper
extension String {
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
