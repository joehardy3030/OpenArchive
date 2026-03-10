import SwiftUI
import AVKit
import MediaPlayer

struct FullPlayerView: View {
    @EnvironmentObject private var playerViewModel: PlayerViewModel
    @Environment(\.dismiss) private var dismiss

    private let utils = Utils()

    var body: some View {
        VStack(spacing: 0) {
            // Pull indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            // Track list
            if let tracks = playerViewModel.currentShow?.mp3Array, !tracks.isEmpty {
                List {
                    ForEach(Array(tracks.enumerated()), id: \.offset) { index, track in
                        HStack {
                            if index == playerViewModel.currentTrackIndex {
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
                                .font(.system(size: 16, weight: index == playerViewModel.currentTrackIndex ? .bold : .regular))
                                .lineLimit(2)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            playerViewModel.playTrack(at: index)
                        }
                    }
                }
                .listStyle(.plain)
            }

            Spacer(minLength: 0)

            // Player controls container
            VStack(spacing: 12) {
                // Show info
                VStack(spacing: 2) {
                    Text(playerViewModel.currentShow?.metadata?.creator ?? "")
                        .font(.system(size: 20, weight: .bold))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    Text(currentTrackName)
                        .font(.system(size: 18, weight: .bold))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    if let venue = playerViewModel.currentShow?.metadata?.venue {
                        Text(venue)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    if let date = playerViewModel.currentShow?.metadata?.date {
                        Text(date)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                // Slider row
                HStack(spacing: 8) {
                    Text(utils.getTimerString(seconds: playerViewModel.currentTime))
                        .font(.system(size: 12, weight: .medium).monospacedDigit())
                        .frame(width: 48, alignment: .trailing)

                    Slider(value: $playerViewModel.sliderValue, in: 0...1) { editing in
                        if !editing {
                            playerViewModel.seek(to: playerViewModel.sliderValue)
                        }
                    }

                    Text(totalTimeString)
                        .font(.system(size: 12, weight: .medium).monospacedDigit())
                        .frame(width: 48, alignment: .leading)
                }
                .padding(.horizontal)

                // Transport controls
                HStack(spacing: 32) {
                    Button { playerViewModel.skipBackward() } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 28))
                    }
                    Button { playerViewModel.togglePlayPause() } label: {
                        Image(systemName: playerViewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 56))
                    }
                    Button { playerViewModel.skipForward() } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 28))
                    }
                    ShareLink(item: shareURL) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 24))
                    }
                }
                .tint(.primary)

                // AirPlay route picker
                AirPlayRoutePickerRepresentable()
                    .frame(width: 40, height: 40)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
    }

    private var currentTrackName: String {
        guard let tracks = playerViewModel.currentShow?.mp3Array,
              playerViewModel.currentTrackIndex < tracks.count else { return "" }
        let t = tracks[playerViewModel.currentTrackIndex]
        return t.title ?? t.name ?? ""
    }

    private var totalTimeString: String {
        let t = playerViewModel.totalTime
        guard t > 0, !t.isNaN, !t.isInfinite else { return "0:00" }
        return utils.getTimerString(seconds: t)
    }

    private var shareURL: URL {
        utils.urlFromIdentifier(identifier: playerViewModel.currentShow?.metadata?.identifier)
    }
}

/// UIKit bridge for AVRoutePickerView (AirPlay button).
struct AirPlayRoutePickerRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.tintColor = .label
        return picker
    }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
