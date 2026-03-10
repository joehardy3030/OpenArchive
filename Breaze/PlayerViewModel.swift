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

    private init() {
        // Timer updates come from AudioPlayerArchive.setupTimer
        player.setupTimer { [weak self] seconds in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.currentTime = seconds ?? 0
                if let duration = self.player.playerQueue?.currentItem?.duration {
                    self.totalTime = CMTimeGetSeconds(duration)
                }
                self.currentShow = self.player.showMetadataModel
                self.currentTrackIndex = self.player.getCurrentTrackIndex()
                self.isStreaming = self.player.isStreaming
            }
        }

        // Observe playback notifications to keep isPlaying in sync.
        NotificationCenter.default.publisher(for: .playbackStarted)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.isPlaying = true
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

    // Restore saved playback state without auto-playing
    func restorePlaybackIfAvailable() {
        _ = player.restorePlaybackState()
        currentShow = player.showMetadataModel
        currentTrackIndex = player.getCurrentTrackIndex()
        isStreaming = player.isStreaming
    }
}

