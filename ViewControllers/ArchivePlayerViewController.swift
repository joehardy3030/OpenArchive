//
//  ArchivePlayerViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 12/20/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import MediaPlayer

class ArchivePlayerViewController: ArchiveSuperViewController {
    var timer: ArchiveTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
     //   setupSlider()
        setupShow()
    }
    
    @IBAction func forwardButton(_ sender: Any) {
        if let q = player?.playerQueue {
            q.advanceToNextItem()
        }
    }
    
    @objc func handleSliderChange() {
        //self.timer?.timerSliderHandler(timerValue: timerSlider.value)
    }
    
    @IBAction func playButton(_ sender: Any) {
        playPause()
    }
    
    @IBAction func timerSlider(_ sender: Any) {
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "currentItem.loadedTimeRanges" {
            setupSong()
        }
    }
    
    func setupSlider() {
        //if let ts = timerSlider {
        //    ts.value = 0.0
        //    ts.addTarget(self, action: #selector(handleSliderChange), for: .valueChanged)
        //}
    }
    
    func setupShow() {
        setupPlayer()
        timer?.setupTimer()  { (seconds: Double?) -> Void in
            self.timerCallback(seconds: seconds)
        }
        setupSong()
    }
        
    func setupSong() {
        setupSongDetails()
        //selectCurrentTrack()
    }
    
    func setupSongDetails() {
        player?.songDetailsModel.songDetailsFromMetadata(row: player?.getCurrentTrackIndex(), showModel: player?.showModel)
//        songLabel.text = player?.songDetailsModel.name
//        dateLabel.text = player?.songDetailsModel.date
 //       venueLabel.text = player?.songDetailsModel.venue
    }
    
    func setupPlayer() {
   //     playPauseButtonImageSetup()
        player?.playerQueue?.addObserver(self, forKeyPath: "currentItem.loadedTimeRanges", options: .new, context: nil)
    }
    
    /*
    func selectCurrentTrack() {
        guard let index = player?.getCurrentTrackIndex() else { return }
        let indexPath = IndexPath(item: index, section: 0)
        self.modalPlayerTableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableView.ScrollPosition.middle)
    }
    */
    
    
    func timerCallback(seconds: Double?) -> Float? {
        //self.currentTimeLabel.text = utils.getTimerString(seconds: seconds)
        //self.totalTimeLabel.text = self.player?.getCurrentTrackTotalTimeString()
        if let duration = self.player?.playerQueue?.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            var percentComplete = Float((seconds ?? 0.0)/(totalSeconds ))
            return percentComplete
        }
        return 0.0
    }
    
    /*
    func playPauseButtonImageSetup() {
        guard let q = player?.playerQueue else { return }
        if q.rate > 0.0 {
            if let _ = playButton {
                if #available(iOS 13.0, *) {
                    playButton.setBackgroundImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
                }
            }
        }
        else {
            if let _ = playButton {
                if #available(iOS 13.0, *) {
                    playButton.setBackgroundImage(UIImage(systemName: "play.circle.fill"), for: .normal)
                }
            }
        }
    }
    */
    
    func playPause() {
        guard let q = player?.playerQueue else { return }
        if q.rate > 0.0 {
            q.pause()
        //    if let _ = playButton {
        //        if #available(iOS 13.0, *) {
        //            playButton.setBackgroundImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        //        }
         //   }
        }
        else {
            q.play()
         //   if let _ = playButton {
         //       if #available(iOS 13.0, *) {
         //           playButton.setBackgroundImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
          //      }
          //  }
        }
    }
    
}
