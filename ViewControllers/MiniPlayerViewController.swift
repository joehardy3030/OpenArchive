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

    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var songLabel: UILabel!
    var player: AudioPlayerArchive?
    var isPlaying = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        newShow()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func playButton(_ sender: Any) {
    }
    
    @IBAction func forwardButton(_ sender: Any) {
    }
    
    func newShow () {
        /*
        if let d = player?.showModel?.metadata?.date {
            songLabel.text = d
        }
        */
        if let _ = player?.playerQueue {
            setupTimer()
        }
        setupSlider()
        player?.setupNotificationView()
        player?.play()
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
        timeSlider.value = 0.0
        timeSlider.addTarget(self, action: #selector(handleSliderChange), for: .valueChanged)
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
            if let duration = self.player?.playerQueue?.currentItem?.duration {
                  let totalSeconds = CMTimeGetSeconds(duration)
                  self.timeSlider.value = Float(seconds/totalSeconds)
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
                if (player?.showModel?.mp3Array?.count)! > 0 {
                    let songName = player?.showModel?.mp3Array?[row].name
                    songLabel.text = songName
                }
               // let indexPath = IndexPath(row: row, section: 0)
                //self.showTableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableView.ScrollPosition.middle)
            }
        }
    }

    func getCurrentTrackIndex() -> Int {
        guard let ci = self.player?.playerQueue?.currentItem else { return 0 }
        let destinationURL = ci.asset.value(forKey: "URL") as? URL
        if let mp3s = player?.showModel?.mp3Array {
            if mp3s.count > 0 {
                for i in 0...(mp3s.count - 1) {
                    if mp3s[i].destination == destinationURL {
                        return i
                        }
                }
            }
        }
        return 0
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
