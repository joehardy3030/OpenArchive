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
    let utils = Utils()
    var nowPlayingInfo = [String : Any]()
    var player: AudioPlayerArchive?
    var timer: ArchiveTimer?
    var currentTrackIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.gray.cgColor
        navigationController?.delegate = self
        //playButton.imageView?.contentMode = .scaleToFill
        initialTimerDefaults()
    }
        
    @IBAction func playButton(_ sender: Any) {
        playPause()
    }
    
    @IBAction func forwardButton(_ sender: Any) {
        player?.playerQueue?.advanceToNextItem()
    }

    @objc func handleSliderChange() {
        self.timer?.timerSliderHandler(timerValue: timeSlider.value)
        /*
        if let duration = self.player?.playerQueue?.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            let value = Float64(timeSlider.value) * totalSeconds
            let seekTime = CMTime(value: Int64(value), timescale: 1)
            self.player?.playerQueue?.seek(to: seekTime, completionHandler: { (completedSeek) in
            })
        }
        */
    }
    
    @IBAction func loadFullPlayer(_ sender: Any) {
        if player?.playerQueue != nil {
            
        
        let sbd = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = sbd.instantiateViewController(withIdentifier: "ModalPlayer") as? ModalPlayerViewController,
            let ad = UIApplication.shared.delegate as? AppDelegate
            else { return }

        if let rvc = ad.window?.rootViewController as? StartViewController {
            prepareModalPlayer(viewController: vc)
            rvc.show(vc, sender: self)
        }
        else {
            print("no root view")
        }
            }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "currentItem.loadedTimeRanges" {
            setupSong()
        }
    }
    
    func prepareModalPlayer(viewController: ModalPlayerViewController) {
        viewController.player = player
        viewController.timer = timer
    }
    
    func currentItemTotalTime() {
        if let ci = self.player?.playerQueue?.currentItem {
            let duration = ci.duration
            let seconds = CMTimeGetSeconds(duration)
            if seconds > 0 && seconds < 100000000.0 {
                totalTimeLabel.text = utils.getTimerString(seconds: seconds)
            }
        }
    }

    func timerCallback(seconds: Double?) {
        self.currentTimeLabel.text = utils.getTimerString(seconds: seconds)
        self.currentItemTotalTime()
        if let duration = self.player?.playerQueue?.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            self.timeSlider.value = Float((seconds ?? 0.0)/(totalSeconds ))
        }
    }


    func setupShow () {
        guard let _ = player?.playerQueue else { return }
        self.player?.playerQueue?.addObserver(self, forKeyPath: "currentItem.loadedTimeRanges", options: .new, context: nil)
        timer?.setupTimer()  { (seconds: Double?) -> Void in
             self.timerCallback(seconds: seconds)
        }
        setupSlider()
        setupSong()
        playPause()
    }
    
    func setupSong() {
        setupSongDetails()
        setupNotificationView()
    }

    func initialTimerDefaults() {
        timer = ArchiveTimer(player: player)
        //timer?.player = player
        timeSlider.value = 0.0
        songLabel.text = ""
        showLabel.text = ""
        venueLabel.text = ""

    }
    /*
    func setupTimer() {
      //  player?.playerQueue?.addObserver(self, forKeyPath: "currentItem.loadedTimeRanges", options: .new, context: nil)
        //track player progress
        initialTimerDefaults()
        let interval = CMTime(value: 1, timescale: 2)
        
        player?.playerQueue?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { (progressTime) in
            let seconds = CMTimeGetSeconds(progressTime)
            let secondsString = String(format: "%02d", Int(seconds) % 60)
            let minutesString = String(format: "%02d", Int(seconds) / 60)
            self.currentTimeLabel.text = ("\(minutesString):\(secondsString)")
            self.currentItemTotalTime()
            if let duration = self.player?.playerQueue?.currentItem?.duration {
                let totalSeconds = CMTimeGetSeconds(duration)
                self.timeSlider.value = Float(seconds/totalSeconds)
            }
        }
        
    }
    */
    
    func setupSlider() {
        if let ts = timeSlider {
            ts.value = 0.0
            ts.addTarget(self, action: #selector(handleSliderChange), for: .valueChanged)
        }
    }

    func setupSongDetails() {
        player?.songDetailsModel.songDetailsFromMetadata(row: player?.getCurrentTrackIndex(), showModel: player?.showModel)
        songLabel.text = player?.songDetailsModel.name
        venueLabel.text = player?.songDetailsModel.venue
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
        print("current track index \(ct)")
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
//        MPRemoteCommandCenter.shared().skipForwardCommand = player?.playerQueue?.advanceToNextItem()
    }
    

    // func setupQueueObserver() {
    //     player?.playerQueue?.addObserver(self, forKeyPath: #keyPath(AVQueuePlayer.status), options: .new, context: nil)
    // }
     //if keyPath == #keyPath(AVQueuePlayer.status) {
     //    print("Got keypath")
     //}

    /*
    func getCurrentTrackIndex() -> Int {
        guard let ci = self.player?.playerQueue?.currentItem else { return 0 }
        let destinationURL = ci.asset.value(forKey: "URL") as? URL
        let name = player?.trackNameFromURL(url: destinationURL)
        if let mp3s = player?.showModel?.mp3Array {
            if mp3s.count > 0 {
                for i in 0...(mp3s.count - 1) {
                    if mp3s[i].name == name {
                        return i
                        }
                }
            }
        }
        return 0
    }
    */
    
    func playPause() {
        guard let q = player?.playerQueue else { return }
        if q.rate > 0.0 {
            q.pause()
            if let _ = playButton {
                if #available(iOS 13.0, *) {
                    playButton.setBackgroundImage(UIImage(systemName: "play"), for: .normal)
                }
            }
        //    isPlaying = false
        }
        else {
            q.play()
            if let _ = playButton {
                if #available(iOS 13.0, *) {
                    playButton.setBackgroundImage(UIImage(systemName: "pause"), for: .normal)
                }
            }
         //   isPlaying = true
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
