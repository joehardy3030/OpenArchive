import SwiftUI

struct DownloadsView: View {
    @StateObject private var viewModel = DownloadsViewModel()
    @Environment(\.miniPlayerInset) private var miniPlayerInset

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.shows, id: \.metadata?.identifier) { show in
                    let id = show.metadata?.identifier ?? ""
                    NavigationLink(value: DownloadedShowDestination(model: show)) {
                        DownloadedShowRow(show: show,
                                          missingCount: viewModel.missingTracks[id]?.count ?? 0,
                                          isRepairing: viewModel.repairingShowIDs.contains(id),
                                          onRepair: { viewModel.repairShow(show) },
                                          onDeleteDownload: { viewModel.deleteShow(show) })
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        viewModel.deleteShow(at: index)
                    }
                }
            }
            .padding(.bottom, miniPlayerInset)
            .navigationTitle("Downloads")
            .navigationDestination(for: DownloadedShowDestination.self) { dest in
                ShowDetailView(metadata: dest.model.metadata ?? ShowMetadata(identifier: "unknown"),
                               showType: .downloaded,
                               existingModel: dest.model)
            }
            .onAppear {
                viewModel.loadDownloads()
            }
            .overlay {
                if viewModel.shows.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView("No Downloads",
                                          systemImage: "arrow.down.circle",
                                          description: Text("Shows you download will appear here."))
                }
            }
        }
    }
}

struct DownloadedShowDestination: Hashable {
    let model: ShowMetadataModel

    func hash(into hasher: inout Hasher) {
        hasher.combine(model.metadata?.identifier)
    }

    static func == (lhs: DownloadedShowDestination, rhs: DownloadedShowDestination) -> Bool {
        lhs.model.metadata?.identifier == rhs.model.metadata?.identifier
    }
}

struct DownloadedShowRow: View {
    let show: ShowMetadataModel
    var missingCount: Int = 0
    var isRepairing: Bool = false
    var onRepair: () -> Void = {}
    var onDeleteDownload: () -> Void = {}

    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                if isRepairing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Repairing…")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                } else if missingCount > 0 {
                    HStack(spacing: 12) {
                        Label("\(missingCount) track\(missingCount == 1 ? "" : "s") missing",
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.orange)
                        Button("Repair") {
                            onRepair()
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .buttonStyle(.borderless)
                    }
                }
                Text(show.metadata?.creator ?? show.metadata?.collection?.joined(separator: ", ") ?? "")
                    .font(.system(size: 18, weight: .bold))
                HStack(spacing: 8) {
                    Text(formatDate(show.metadata?.date))
                        .font(.system(size: 17, weight: .bold))
                    if let type = show.metadata?.recordingType {
                        RecordingTypeBadge(type: type)
                    }
                }
                if let loc = show.metadata?.displayVenueLine {
                    Text(loc)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                if let src = show.metadata?.source, !src.isEmpty {
                    Text(src.joined(separator: "; "))
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                if let transferer = show.metadata?.transferer, !transferer.isEmpty {
                    Text(transferer)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                if let rating = show.metadata?.avg_rating, let reviews = show.metadata?.num_reviews {
                    Text("\(String(format: "%.1f", rating)) stars  \(reviews) ratings")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if !isRepairing && missingCount == 0 {
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
        .alert("Delete Download?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                onDeleteDownload()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the downloaded files from this device. You can download the show again afterward.")
        }
    }

    private func formatDate(_ dateString: String?) -> String {
        guard let dateString else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }
        return dateString
    }
}
