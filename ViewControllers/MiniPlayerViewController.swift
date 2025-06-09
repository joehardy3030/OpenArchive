//
//  MiniPlayerViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/20/20.
//  Copyright 2020 Carquinez. All rights reserved.
//

import UIKit
import MediaPlayer

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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.gray.cgColor
        navigationController?.delegate = self
        notificationCenter.addObserver(self, selector: #selector(playbackDidStart), name: .playbackStarted, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackDidPause), name: .playbackPaused, object: self.player?.playerQueue)
        initialDefaults()
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // DO NOT remove observer here, the MiniPlayer is persistent.
        // It should only be removed in deinit or when the queue is replaced.
    }

    @IBAction func playButton(_ sender: Any) {
        playPause()
    }
    
    @IBAction func forwardButton(_ sender: Any) {
        if let q = player?.playerQueue {
            q.advanceToNextItem()
        }
    }

    @objc func handleSliderChange() {
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
                print("ready to play")
            case .failed:
                print("failed ")
            case .unknown:
                print("unknown status")
            default:
                print("nope")
            }
            
        } else if keyPath == #keyPath(AVQueuePlayer.currentItem) {
            print("MiniPlayer KVO: AVQueuePlayer.currentItem changed.") // DIAGNOSTIC
            // The current item of the player queue has changed.
            // This happens when a track finishes or when advanceToNextItem() is called.
            DispatchQueue.main.async {
                // It's important to remove observer from the old item and add to the new one for 'status'
                if let oldItem = change?[.oldKey] as? AVPlayerItem {
                    oldItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: nil)
                }
                if let newItem = change?[.newKey] as? AVPlayerItem {
                    newItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: nil)
                }
               // print("MiniPlayer KVO: Calling self.setupSong()") // DIAGNOSTIC
                self.setupSong() // This will update UI and Now Playing info
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func setupQueueTimerCallback() {
        player?.setupTimer()  { (seconds: Double?) -> Void in
             self.timerCallback(seconds: seconds)
        }
    }
        
    func setupSlider() {
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
        setupSlider()
        setupSong()
        playPause()
    }

    func setupSong() {
        //print("MiniPlayer: setupSong() called.") // DIAGNOSTIC
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
}
