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
    var isObservingPlayer = false

    
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
        removePlayerObserver()
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
    }
        
    func setupShow () {
        guard let _ = player?.playerQueue else { return }
        setupPlayerObserver()
        setupQueueTimerCallback()
        setupSlider()
        setupSong()
        playPause()
    }

    func setupSong() {
        setupSongDetails()
        setupNotificationView()
    }
    

    func setupSongDetails() {
        player?.songDetailsModel.songDetailsFromMetadata(row: player?.getCurrentTrackIndex(), showModel: player?.showMetadataModel)
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
            else { return }
        guard let ct = player?.getCurrentTrackIndex()
        else {
            print("No current track index")
            return
        }
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

    // Add methods to manage the KVO observer
    func setupPlayerObserver() {
        guard let queue = player?.playerQueue else { return }
        if !isObservingPlayer {
            queue.addObserver(self, forKeyPath: "currentItem.status", options: .new, context: nil)
            isObservingPlayer = true
            print("Added player observer in MiniPlayerViewController")
        }
    }

    func removePlayerObserver() {
        if isObservingPlayer, let queue = player?.playerQueue {
            do {
                queue.removeObserver(self, forKeyPath: "currentItem.status")
                isObservingPlayer = false
                print("Removed player observer in MiniPlayerViewController")
            } catch {
                print("Failed to remove observer: \(error)")
                isObservingPlayer = false // Still set to false even if removal fails
            }
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
