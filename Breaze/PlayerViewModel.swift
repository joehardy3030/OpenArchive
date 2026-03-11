import Foundation
import Combine
import AVFoundation

/// Observable wrapper around `AudioPlayerArchive` so SwiftUI views can react to playback changes.
final class PlayerViewModel: ObservableObject {
    static let shared = PlayerViewModel()

    private let player = AudioPlayerArchive.shared
    private var cancellables = Set<AnyCancellable>()

    // Basic published properties the UI cares about
    @Published var currentShow: ShowMetadataModel?
    @Published var currentTrackIndex: Int = 0
    @Published var isPlaying: Bool = false
    @Published var isStreaming: Bool = false
    @Published var currentTime: Double = 0
    @Published var totalTime: Double = 0
    @Published var sliderValue: Double = 0

    private var isUserDraggingSlider = false

    private init() {
        // Observe playback notifications to keep isPlaying in sync.
        NotificationCenter.default.publisher(for: .playbackStarted)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.isPlaying = true
                    // Re-register the periodic timer each time a new queue starts playing,
                    // since playerQueue is nil at init and replaced on every stream/play call.
                    self?.setupPlaybackTimer()
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .playbackPaused)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.isPlaying = false
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .playbackStopped)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.isPlaying = false
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Timer

    private func setupPlaybackTimer() {
        player.setupTimer { [weak self] seconds in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.currentTime = seconds ?? 0
                if let duration = self.player.playerQueue?.currentItem?.duration {
                    let total = CMTimeGetSeconds(duration)
                    self.totalTime = total
                    if !self.isUserDraggingSlider, total > 0 {
                        self.sliderValue = (seconds ?? 0) / total
                    }
                }
                self.currentShow = self.player.showMetadataModel
                self.currentTrackIndex = self.player.getCurrentTrackIndex()
                self.isStreaming = self.player.isStreaming
            }
        }
    }

    // MARK: - Control surface

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func skipForward() {
        player.playerQueue?.advanceToNextItem()
    }

    func skipBackward() {
        player.rewindToPreviousItem()
    }

    func seek(to fraction: Double) {
        guard fraction >= 0, fraction <= 1 else { return }
        player.timerSliderHandler(timerValue: Float(fraction))
    }

    func playTrack(at index: Int) {
        guard let show = currentShow else { return }
        player.pause()
        player.showMetadataModel = show
        if isStreaming {
            player.loadStreamingQueuePlayer(startingAt: index)
        } else if let tracks = show.mp3Array {
            player.loadQueuePlayer(tracks: tracks, startingAt: index)
        }
        player.play()
    }

    func restorePlaybackIfAvailable() {
        _ = player.restorePlaybackState()
        currentShow = player.showMetadataModel
        currentTrackIndex = player.getCurrentTrackIndex()
        isStreaming = player.isStreaming
    }
}

