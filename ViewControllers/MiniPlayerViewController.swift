//
//  MiniPlayerViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/20/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import MediaPlayer

class MiniPlayerViewController: UIViewController {

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var showLabel: UILabel!
    @IBOutlet weak var venueLabel: UILabel!
    @IBOutlet weak var songLabel: UILabel!
    let notificationCenter: NotificationCenter = .default
    let utils = Utils()
    var nowPlayingInfo = [String : Any]()
    var player: AudioPlayerArchive?
    var timer: ArchiveTimer?
    var currentTrackIndex = 0
    //private var playerItemContext = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.gray.cgColor
        navigationController?.delegate = self
        notificationCenter.addObserver(self, selector: #selector(playbackDidStart), name: .playbackStarted, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackDidPause), name: .playbackPaused, object: self.player?.playerQueue)
        initialDefaults()
        //setupQueueCallback()
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
        self.timer?.timerSliderHandler(timerValue: timeSlider.value)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        //if keyPath == "currentItem.loadedTimeRanges" {
           // setupSong()
       // }
        //if keyPath == "currentItem.status" {
       //     print("status")
       // }
        
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
        timer?.setupTimer()  { (seconds: Double?) -> Void in
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
        
        let sbd = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = sbd.instantiateViewController(withIdentifier: "ModalPlayer") as? ModalPlayerViewController,
            //let ad = UIApplication.shared.delegate as? AppDelegate
            let sd = UIApplication.shared.delegate as? SceneDelegate
            else { return }

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
        viewController.player = player
        viewController.timer = timer
    }

    
    func initialDefaults() {
        timeSlider.value = 0.0
        songLabel.text = ""
        showLabel.text = ""
        venueLabel.text = ""
    }
        
    func setupShow () {
        guard let _ = player?.playerQueue else { return }
        //self.player?.playerQueue?.addObserver(self, forKeyPath: "currentItem.loadedTimeRanges", options: .new, context: nil)
        self.player?.playerQueue?.addObserver(self, forKeyPath: "currentItem.status", options: .new, context: nil)
        //timer? = ArchiveTimer(player: player)
        //timer?.setupTimer()  { (seconds: Double?) -> Void in
        //     self.timerCallback(seconds: seconds)
        //}
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
        player?.songDetailsModel.songDetailsFromMetadata(row: player?.getCurrentTrackIndex(), showModel: player?.showModel)
        songLabel.text = player?.songDetailsModel.name
        venueLabel.text = player?.songDetailsModel.venue
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
            let mp3s = player?.showModel?.mp3Array,
            let md = player?.showModel?.metadata
            else { return }
        guard let ct = player?.getCurrentTrackIndex()
        else {
            print("No current track index")
            return
        }
        nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = mp3s[ct].title
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = String(md.date! + ", " + md.coverage!)
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Grateful Dead"
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
            //if let _ = playButton {
            //    if #available(iOS 13.0, *) {
            //        playButton.setBackgroundImage(UIImage(systemName: "play"), for: .normal)
            //    }
            //}
        }
        else {
            player?.play()
            //if let _ = playButton {
            //    if #available(iOS 13.0, *) {
            //        playButton.setBackgroundImage(UIImage(systemName: "pause"), for: .normal)
            //    }
            //}
        }
    }
    
}


extension MiniPlayerViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let _ = viewController as? ArchiveSuperViewController {
            // vc.miniPlayer?.player = player
            //  vc.prevController = self
        }
    }
}

private extension MiniPlayerViewController {
    @objc private func playbackDidStart(_ notification: Notification) {
        guard let _ = playButton else { return }
        if #available(iOS 13.0, *) {
            playButton.setBackgroundImage(UIImage(systemName: "pause"), for: .normal)
        }
        //print("Item playing -- miniplayer")
    }
    
    @objc private func playbackDidPause(_ notification: Notification) {
        guard let _ = playButton else { return }
        if #available(iOS 13.0, *) {
            playButton.setBackgroundImage(UIImage(systemName: "play"), for: .normal)
        }
        //print("Item paused -- miniplayer ")
    }
}
