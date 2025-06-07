import UIKit
import AVKit
import AVFoundation

// Protocol that defines the player observation capabilities
@objc protocol PlayerObserver: NSObjectProtocol {
    var player: AudioPlayerArchive { get }
    var isObservingPlayer: Bool { get set }
    var notificationCenter: NotificationCenter { get }
    
    func setupPlayerObserver()
    func removePlayerObserver()
    func handlePlayerReadyToPlay()
    
    // Notification handlers - need to be @objc for #selector
    @objc func playbackDidStart(_ notification: Notification)
    @objc func playbackDidPause(_ notification: Notification)
    @objc func playbackDidFail(_ notification: Notification)
}

// Default implementation for any class that conforms to PlayerObserver
// Restrict this extension to NSObject subclasses only
extension PlayerObserver where Self: NSObject {
    func setupNotificationObservers() {
        notificationCenter.addObserver(self, selector: #selector(playbackDidStart), name: .playbackStarted, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackDidPause), name: .playbackPaused, object: player.playerQueue)
        notificationCenter.addObserver(self, selector: #selector(playbackDidFail), name: .playbackFailed, object: nil)
    }
    
    func setupPlayerObserver() {
        guard let queue = player.playerQueue else { return }
        if !isObservingPlayer {
            queue.addObserver(self, forKeyPath: "currentItem.status", options: .new, context: nil)
            isObservingPlayer = true
            print("Added player observer in \(type(of: self))")
        }
    }
    
    func removePlayerObserver() {
        if isObservingPlayer, let queue = player.playerQueue {
            do {
                queue.removeObserver(self, forKeyPath: "currentItem.status")
                isObservingPlayer = false
                print("Removed player observer in \(type(of: self))")
            } catch {
                print("Failed to remove observer: \(error)")
                isObservingPlayer = false
            }
        }
    }
    
    func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVQueuePlayer.currentItem.status) {
            let status: AVPlayerItem.Status
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            // Switch over status value
            switch status {
            case .readyToPlay:
                handlePlayerReadyToPlay()
                print("ready to play in \(type(of: self))")
            case .failed:
                // This is now handled by the .playbackFailed notification
                break
            case .unknown:
                print("unknown status")
            default:
                print("nope")
            }
        }
    }
    
    // Default implementation for playbackDidFail
    func playbackDidFail(_ notification: Notification) {
        if let error = notification.userInfo?["error"] as? Error {
            print("Playback failed with error: \(error.localizedDescription)")
        }
        
        // Default implementation - can be overridden
        if let viewController = self as? UIViewController {
            let isStreaming = notification.userInfo?["isStreaming"] as? Bool ?? false
            let message = isStreaming ? "Could not stream the track. Please check your internet connection and try again." : "Could not play the downloaded track. The file may be corrupt or missing."
            let alert = UIAlertController(title: "Playback Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            viewController.present(alert, animated: true, completion: nil)
        }
    }
}

// Optional protocol for view controllers that need to observe rewind events
@objc protocol PlayerRewindObserver {
    @objc func playbackDidRewind(_ notification: Notification)
}
