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
    var player: AudioPlayerArchive?
    var currentTrackIndex = 0
    var isPlaying = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.gray.cgColor
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupShow()
    }
    
    @IBAction func playButton(_ sender: Any) {
        playPause()
    }
    
    @IBAction func forwardButton(_ sender: Any) {
        player?.playerQueue?.advanceToNextItem()
    }
    
    func setupShow () {
        if let _ = player?.playerQueue {
            setupTimer()
        }
        setupSlider()
        //setupTimer()
        setupShowDetails()
        player?.setupNotificationView()
        //player?.play()
        if #available(iOS 13.0, *) {
            if let pb = playButton {
                pb.setImage(UIImage(systemName: "pause"), for: .normal)
            }
            
        }
    }
    
    func setupShowDetails() {
        let row = getCurrentTrackIndex()
        currentTrackIndex = row
      //  print(player?.showModel?.metadata?.coverage)
        if let c = player?.showModel?.mp3Array?.count {
            if c > 0 {
                let songName = player?.showModel?.mp3Array?[row].title
                songLabel.text = songName
                showLabel.text = player?.showModel?.metadata?.date
                venueLabel.text = player?.showModel?.metadata?.venue
            }
        }
    }
    
    @objc func handleSliderChange() {
        if let duration = self.player?.playerQueue?.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            let value = Float64(timeSlider.value) * totalSeconds
            let seekTime = CMTime(value: Int64(value), timescale: 1)
            self.player?.playerQueue?.seek(to: seekTime, completionHandler: { (completedSeek) in
            })
        }
    }

    func setupSlider() {
        if let ts = timeSlider {
            ts.value = 0.0
            ts.addTarget(self, action: #selector(handleSliderChange), for: .valueChanged)
        }
    }
    
    func setupTimer() {
        player?.playerQueue?.addObserver(self, forKeyPath: "currentItem.loadedTimeRanges", options: .new, context: nil)
        //track player progress
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
    
    func currentItemTotalTime() {
        if let ci = self.player?.playerQueue?.currentItem {
            let duration = ci.duration
            let seconds = CMTimeGetSeconds(duration)
            if seconds > 0 && seconds < 100000000.0 {
                let secondsText =  String(format: "%02d", Int(seconds) % 60)
                let minutesText = String(format: "%02d", Int(seconds) / 60)
                totalTimeLabel.text = "\(minutesText):\(secondsText)"
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "currentItem.loadedTimeRanges" {
            isPlaying = true
            if let ci = self.player?.playerQueue?.currentItem {
                let duration = ci.duration
                let seconds = CMTimeGetSeconds(duration)
                if seconds > 0 && seconds < 100000000.0 {
                    let secondsText =  String(format: "%02d", Int(seconds) % 60)
                    let minutesText = String(format: "%02d", Int(seconds) / 60)
                    totalTimeLabel.text = "\(minutesText):\(secondsText)"
                }
                let row = getCurrentTrackIndex()
                currentTrackIndex = row
                if (player?.showModel?.mp3Array?.count)! > 0 {
                    let songName = player?.showModel?.mp3Array?[row].title
                    songLabel.text = songName
                    showLabel.text = player?.showModel?.metadata?.date
                    venueLabel.text = player?.showModel?.metadata?.venue
                }
            }
        }
    }

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

    func playPause() {
        if player?.playerQueue?.rate ?? 0.0 > 0.0 {
            player?.playerQueue?.pause()
            if let _ = playButton {
                if #available(iOS 13.0, *) {
                    playButton.setImage(UIImage(systemName: "play"), for: .normal)
                }
            }
            isPlaying = false
        }
        else {
            player?.playerQueue?.play()
            if let _ = playButton {
                if #available(iOS 13.0, *) {
                    playButton.setImage(UIImage(systemName: "pause"), for: .normal)
                }
            }
            isPlaying = true
        }
    }
    
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
