//
//  MiniPlayerViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/20/20.
//  Copyright 2020 Carquinez. All rights reserved.
//

import UIKit
import MediaPlayer

extension Notification.Name {
    static let modalPlayerDidDismiss = Notification.Name("modalPlayerDidDismiss")
}

class MiniPlayerViewController: UIViewController {

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var currentTimeLabel: UILabel! {
        didSet {
            currentTimeLabel.textAlignment = .right
            currentTimeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            let widthConstraint = currentTimeLabel.widthAnchor.constraint(equalToConstant: 60)
            widthConstraint.priority = UILayoutPriority(999) // High but not required
            widthConstraint.isActive = true
            currentTimeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: currentTimeLabel.font.pointSize, weight: .medium)
        }
    }
    @IBOutlet weak var totalTimeLabel: UILabel! {
        didSet {
            totalTimeLabel.textAlignment = .left
            totalTimeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            let widthConstraint = totalTimeLabel.widthAnchor.constraint(equalToConstant: 60)
            widthConstraint.priority = UILayoutPriority(999) // High but not required
            widthConstraint.isActive = true
            totalTimeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: totalTimeLabel.font.pointSize, weight: .medium)
        }
    }
    @IBOutlet weak var timeSlider: UISlider! {
        didSet {
            timeSlider.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }
    }
    @IBOutlet weak var showLabel: UILabel!
    @IBOutlet weak var venueLabel: UILabel!
    @IBOutlet weak var songLabel: UILabel!
    let notificationCenter: NotificationCenter = .default
    let utils = Utils()
    var nowPlayingInfo = [String : Any]()
    var player: AudioPlayerArchive?
    var currentTrackIndex = 0
    private var isObservingPlayer = false
    private weak var observedQueue: AVQueuePlayer?
    private var miniPlayerKVOContext = 0
    
    // For restored playback state (not yet playing)
    private var restoredState: PlaybackState?
    private var isRestoredStateReady = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.gray.cgColor
        navigationController?.delegate = self
        notificationCenter.addObserver(self, selector: #selector(playbackDidStart), name: .playbackStarted, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackDidPause), name: .playbackPaused, object: self.player?.playerQueue)
        notificationCenter.addObserver(self, selector: #selector(modalPlayerDidDismiss), name: .modalPlayerDidDismiss, object: nil)
        initialDefaults()
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // DO NOT remove observer here, the MiniPlayer is persistent.
        // It should only be removed in deinit or when the queue is replaced.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // When the MiniPlayer is about to appear, ensure its timer callback is active.
        // This is important if ModalPlayerViewController was active and set its own timer.
        print("MiniPlayer: viewWillAppear - calling setupQueueTimerCallback()") // DIAGNOSTIC
        setupQueueTimerCallback()
        
        // Optionally, if a full refresh of song details is also needed upon appearing:
        // self.setupSong() 
    }

    @IBAction func playButton(_ sender: Any) {
        // If we have a restored state that hasn't been loaded into the player yet
        if let state = restoredState, !isRestoredStateReady {
            startRestoredPlayback(state: state)
        } else {
            playPause()
        }
    }
    
    @IBAction func forwardButton(_ sender: Any) {
        if let q = player?.playerQueue {
            q.advanceToNextItem()
        }
    }

    @objc func handleSliderChange() {
        print("MiniPlayer timerSliderHander")
        self.player?.timerSliderHandler(timerValue: timeSlider.value)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard context == &miniPlayerKVOContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
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
                setupSong()
                print("MiniPlayer ready to play")
            case .failed:
                print("MiniPlayer failed ")
            case .unknown:
                print("MiniPlayer unknown status")
            default:
                print("nope")
            }
            
        } else if keyPath == #keyPath(AVQueuePlayer.currentItem) {
            print("MiniPlayer KVO: AVQueuePlayer.currentItem changed.") // DIAGNOSTIC
            // The current item of the player queue has changed.
            // This happens when a track finishes or when advanceToNextItem() is called.
            DispatchQueue.main.async {
                // It's important to remove observer from the old item and add to the new one for 'status',
                // using the correct KVO context.
                if let oldItem = change?[.oldKey] as? AVPlayerItem {
                    oldItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &self.miniPlayerKVOContext)
                    print("MiniPlayer oldItem change")
                }
                if let newItem = change?[.newKey] as? AVPlayerItem {
                    newItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &self.miniPlayerKVOContext)
                    print("MiniPlayer newItem change")
                }
               // print("MiniPlayer KVO: Calling self.setupSong()") // DIAGNOSTIC
                self.setupSong() // This will update UI and Now Playing info
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func setupQueueTimerCallback() {
        print("MiniPlayer SetupQueueTimerCallback")
        player?.setupTimer()  { (seconds: Double?) -> Void in
             self.timerCallback(seconds: seconds)
        }

    }
        
    func setupSlider() {
        print("MiniPlayer Slider")
        if let ts = timeSlider {
            ts.value = 0.0
            ts.addTarget(self, action: #selector(handleSliderChange), for: .valueChanged)
        }
    }

    @available(iOS 13.0, *)
    @IBAction func loadFullPlayer(_ sender: Any) {
        if player?.playerQueue != nil {
            
            guard let sd = self.view.window?.windowScene?.delegate as? SceneDelegate else { return }
            let vc = ModalPlayerViewController()
            
            if let rvc = sd.window?.rootViewController as? StartViewController {
                prepareModalPlayer(viewController: vc)
                rvc.show(vc, sender: self)
            }
            else {
                print("no root view")
            }
        }
    }

    func prepareModalPlayer(viewController: ModalPlayerViewController) {

    }

    
    func initialDefaults() {
        timeSlider.value = 0.0
        songLabel.text = ""
        showLabel.text = ""
        venueLabel.text = ""
        currentTimeLabel.text = "0:00"
        totalTimeLabel.text = "0:00"
    }
        
    func setupShow () {
        setupPlayerObserver()
        if player?.playerQueue == nil {
             initialDefaults()
             return
        }
        setupQueueTimerCallback()
        //self.player?.setupTimer()  { (seconds: Double?) -> Void in
        //     self.timerCallback(seconds: seconds)
        //}
        setupSlider()
        setupSong()
        playPause()
    }

    func setupSong() {
        print("MiniPlayer: setupSong() called.") // DIAGNOSTIC
        setupSongDetails()
        setupNotificationView()
        setupQueueTimerCallback() // Ensure timer callback is set for MiniPlayer
    }
    

    func setupSongDetails() {
        let currentIndex = player?.getCurrentTrackIndex() // DIAGNOSTIC
        //print("MiniPlayer setupSongDetails: Current track index from player: \(String(describing: currentIndex))") // DIAGNOSTIC
        player?.songDetailsModel.songDetailsFromMetadata(row: currentIndex, showModel: player?.showMetadataModel)
        //print("MiniPlayer setupSongDetails: Song name to set: \(String(describing: player?.songDetailsModel.name))") // DIAGNOSTIC
        songLabel.text = player?.songDetailsModel.name
        venueLabel.text = player?.songDetailsModel.venue
        showLabel.text = player?.showMetadataModel?.metadata?.creator
    }
    
    func timerCallback(seconds: Double?) {
        self.currentTimeLabel.text = utils.getTimerString(seconds: seconds)
        self.totalTimeLabel.text = self.player?.getCurrentTrackTotalTimeString()
        if let duration = self.player?.playerQueue?.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            self.timeSlider.value = Float((seconds ?? 0.0)/(totalSeconds ))
        }
    }

    func setupNotificationView() {
        guard let ci = self.player?.playerQueue?.currentItem,
            let mp3s = player?.showMetadataModel?.mp3Array,
            let md = player?.showMetadataModel?.metadata
            else { 
                print("MiniPlayer setupNotificationView: Missing data, returning.") // DIAGNOSTIC
                return 
            }
        guard let ct = player?.getCurrentTrackIndex()
        else {
            print("MiniPlayer setupNotificationView: No current track index, returning.") // DIAGNOSTIC
            return
        }
        print("MiniPlayer setupNotificationView: Updating for track index \(ct), title: \(String(describing: mp3s[ct].title ?? mp3s[ct].name))") // DIAGNOSTIC
        nowPlayingInfo = [String : Any]()
        if let _ = mp3s[ct].title {
            nowPlayingInfo[MPMediaItemPropertyTitle] = mp3s[ct].title
        }
        else {
            nowPlayingInfo[MPMediaItemPropertyTitle] = mp3s[ct].name
        }
        
        // Safely handle date and coverage
        var albumTitle = ""
        if let date = md.date {
            albumTitle += date
        }
        if let coverage = md.coverage {
            if !albumTitle.isEmpty {
                albumTitle += ", "
            }
            albumTitle += coverage
        }
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = albumTitle
        
        nowPlayingInfo[MPMediaItemPropertyArtist] = md.creator
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = CMTimeGetSeconds(ci.duration)
        if let seconds = player?.playerQueue?.currentTime().seconds {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = seconds
        }
        
        if let image = UIImage(named: "Chateau80") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] =
                MPMediaItemArtwork(boundsSize: image.size) { size in
                    return image
            }
        }
        else { print("no image")}
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func playPause() {
        guard let q = player?.playerQueue else { return }
        if q.rate > 0.0 {
            player?.pause()
        }
        else {
            player?.play()
        }
    }
    
    // MARK: - Playback State Restoration
    
    /// Attempt to restore saved playback state (call after player is set)
    func attemptRestorePlaybackState() {
        guard let player = player else { return }
        
        // Don't restore if already playing
        if player.playerQueue?.rate ?? 0 > 0 { return }
        
        // Try to restore state
        if let state = player.restorePlaybackState() {
            self.restoredState = state
            self.isRestoredStateReady = false
            
            // Display the restored show info without starting playback
            displayRestoredState(state)
            
            print("MiniPlayer: Restored playback state displayed, waiting for user to tap play")
        }
    }
    
    /// Display the restored state in the UI (paused, not playing)
    private func displayRestoredState(_ state: PlaybackState) {
        guard let mp3s = state.showMetadataModel.mp3Array,
              state.trackIndex < mp3s.count else { return }
        
        let track = mp3s[state.trackIndex]
        let metadata = state.showMetadataModel.metadata
        
        // Update labels
        songLabel.text = track.title ?? track.name ?? "Unknown Track"
        venueLabel.text = metadata?.venue ?? metadata?.coverage ?? ""
        showLabel.text = metadata?.creator ?? ""
        
        // Show saved position
        currentTimeLabel.text = utils.getTimerString(seconds: state.playbackPosition)
        totalTimeLabel.text = "Tap to play"
        
        // Reset slider
        timeSlider.value = 0.0
        
        // Ensure play button shows play icon
        if #available(iOS 13.0, *) {
            playButton.setBackgroundImage(UIImage(systemName: "play"), for: .normal)
        }
        
        print("MiniPlayer: Displaying restored state - \(track.title ?? track.name ?? "Unknown")")
    }
    
    /// Actually start playback of the restored state
    private func startRestoredPlayback(state: PlaybackState) {
        guard let player = player else { return }
        
        print("MiniPlayer: Starting restored playback")
        
        // Show loading indicator
        songLabel.text = "Loading..."
        
        player.prepareRestoredPlayback(state: state) { [weak self] success in
            guard let self = self else { return }
            
            if success {
                self.isRestoredStateReady = true
                self.setupPlayerObserver()
                self.setupQueueTimerCallback()
                self.setupSlider()
                self.setupSong()
                self.player?.play()
                
                // Clear the restored state since we're now playing
                self.restoredState = nil
                
                print("MiniPlayer: Restored playback started successfully")
            } else {
                print("MiniPlayer: Failed to start restored playback")
                self.initialDefaults()
                self.restoredState = nil
            }
        }
    }
    
    deinit {
        notificationCenter.removeObserver(self)
        removePlayerObserver()
    }

    func setupPlayerObserver() {
        if let queue = observedQueue {
            queue.removeObserver(self, forKeyPath: "currentItem.status", context: &miniPlayerKVOContext)
            self.observedQueue = nil
            isObservingPlayer = false
            print("MiniPlayer: Removed old observer.")
        }

        guard let newQueue = player?.playerQueue else { return }

        newQueue.addObserver(self, forKeyPath: "currentItem.status", options: .new, context: &miniPlayerKVOContext)
        isObservingPlayer = true
        self.observedQueue = newQueue
        print("MiniPlayer: Added new observer.")
    }

    func removePlayerObserver() {
        if let queue = observedQueue {
            queue.removeObserver(self, forKeyPath: "currentItem.status", context: &miniPlayerKVOContext)
            isObservingPlayer = false
            self.observedQueue = nil
            print("MiniPlayer: Removed observer in deinit.")
        }
    }
}


extension MiniPlayerViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let _ = viewController as? ArchiveSuperViewController {
        }
    }
}

private extension MiniPlayerViewController {
    @objc private func playbackDidStart(_ notification: Notification) {
        guard let _ = playButton else { return }
        if #available(iOS 13.0, *) {
            playButton.setBackgroundImage(UIImage(systemName: "pause"), for: .normal)
        }
    }
    
    @objc private func playbackDidPause(_ notification: Notification) {
        guard let _ = playButton else { return }
        if #available(iOS 13.0, *) {
            playButton.setBackgroundImage(UIImage(systemName: "play"), for: .normal)
        }
    }
    
    @objc private func modalPlayerDidDismiss(_ notification: Notification) {
        print("MiniPlayer: ModalPlayer dismissed. Reclaiming timer callback.")
        setupQueueTimerCallback()
    }

}
