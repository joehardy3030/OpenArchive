//
//  ArchiveSuperViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/24/20.
//  Copyright 2020 Carquinez. All rights reserved.
//

import UIKit
import AVFoundation

class ArchiveSuperViewController: UIViewController {
    var network: NetworkUtility!
    let utils = Utils()
    let archiveAPI = ArchiveAPI()
    var prevController: ArchiveSuperViewController?
    var miniPlayer: MiniPlayerViewController?
    let player = AudioPlayerArchive.shared
    var isPlaying = false
    var isObservingPlayer = false // Track observer state

    override func viewDidLoad() {
        super.viewDidLoad()
        network = NetworkUtility()
        navigationController?.delegate = self
        setupNotificationObservers()
        setupPlayerObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removePlayerObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        removePlayerObserver()
    }
    
    // MARK: - Player Observer Methods
    
    /// Sets up observers for player notifications
    func setupNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(playbackDidStart), name: .playbackStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playbackDidPause), name: .playbackPaused, object: player.playerQueue)
        NotificationCenter.default.addObserver(self, selector: #selector(playbackDidFail), name: .playbackFailed, object: nil)
    }
    
    /// Sets up KVO observer for the player queue
    func setupPlayerObserver() {
        guard let queue = player.playerQueue else { return }
        if !isObservingPlayer {
            queue.addObserver(self, forKeyPath: "currentItem.status", options: .new, context: nil)
            isObservingPlayer = true
            print("Added player observer in \(type(of: self))")
        }
    }
    
    /// Removes KVO observer from the player queue
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
    
    /// Handle player ready state - to be overridden by subclasses
    func handlePlayerReadyToPlay() {
        // Default implementation - override in subclasses
        print("Player ready to play in base class")
    }
    
    // MARK: - KVO Observer
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
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
                // This can be handled by the .playbackFailed notification
                break
            case .unknown:
                print("unknown status")
            default:
                print("nope")
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // MARK: - Notification Handlers
    
    @objc func playbackDidStart(_ notification: Notification) {
        // Default implementation - override in subclasses
        print("Playback started in base class")
    }
    
    @objc func playbackDidPause(_ notification: Notification) {
        // Default implementation - override in subclasses
        print("Playback paused in base class")
    }
    
    @objc func playbackDidFail(_ notification: Notification) {
        if let error = notification.userInfo?["error"] as? Error {
            print("Playback failed with error: \(error.localizedDescription)")
        }
        
        // Default implementation - can be overridden
        let isStreaming = notification.userInfo?["isStreaming"] as? Bool ?? false
        let message = isStreaming ? "Could not stream the track. Please check your internet connection and try again." : "Could not play the downloaded track. The file may be corrupt or missing."
        let alert = UIAlertController(title: "Playback Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

extension ArchiveSuperViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let _ = viewController as? ArchiveSuperViewController {
        }
    }
}

@available(iOS 13.0, *)
extension ArchiveSuperViewController {
    func getMiniPlayerController() -> MiniPlayerViewController? {
        guard let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate else { return nil }
       
        if let vcs = sceneDelegate.window?.rootViewController?.children
        {
            for vc in vcs {
                if let mp = vc as? MiniPlayerViewController {
                    return mp
                }
            }
        }
        return nil
    }
}
