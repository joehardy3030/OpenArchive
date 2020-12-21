//
//  ModalPlayerViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 8/2/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import MediaPlayer

class ModalPlayerViewController: ArchiveSuperViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var venueLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timerSlider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var modalPlayerTableView: UITableView!
    var timer: ArchiveTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.modalPlayerTableView.delegate = self
        self.modalPlayerTableView.dataSource = self
        initialDefaults()
        setupShow()
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
        self.timer?.timerSliderHandler(timerValue: timerSlider.value)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "currentItem.loadedTimeRanges" {
            setupSong()
        }
    }

    @IBAction func timerSlider(_ sender: Any) {
        
    }
    
    func setupSlider() {
        if let ts = timerSlider {
            ts.value = 0.0
            ts.addTarget(self, action: #selector(handleSliderChange), for: .valueChanged)
        }
    }

    func initialDefaults() {
        dateLabel.text = ""
        songLabel.text = ""
        venueLabel.text = ""
      }

    func setupShow() {
        guard let _ = player?.playerQueue else { return }
        playPauseButtonImageSetup()
        player?.playerQueue?.addObserver(self, forKeyPath: "currentItem.loadedTimeRanges", options: .new, context: nil)
        timer?.setupTimer()  { (seconds: Double?) -> Void in
             self.timerCallback(seconds: seconds)
        }
        setupSlider()
        setupSong()
    }
        
    func setupSong() {
        setupSongDetails()
        selectCurrentTrack()
    }
    
    func setupSongDetails() {
        player?.songDetailsModel.songDetailsFromMetadata(row: player?.getCurrentTrackIndex(), showModel: player?.showModel)
        songLabel.text = player?.songDetailsModel.name
        dateLabel.text = player?.songDetailsModel.date
        venueLabel.text = player?.songDetailsModel.venue
    }    
   
    func selectCurrentTrack() {
        guard let index = player?.getCurrentTrackIndex() else { return }
        let indexPath = IndexPath(item: index, section: 0)
        self.modalPlayerTableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableView.ScrollPosition.middle)
    }
    
    func timerCallback(seconds: Double?) {
        self.currentTimeLabel.text = utils.getTimerString(seconds: seconds)
        self.totalTimeLabel.text = self.player?.getCurrentTrackTotalTimeString()
        if let duration = self.player?.playerQueue?.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            self.timerSlider.value = Float((seconds ?? 0.0)/(totalSeconds ))
        }
    }
    
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
    
    func playPause() {
        guard let q = player?.playerQueue else { return }
        if q.rate > 0.0 {
            q.pause()
            if let _ = playButton {
                if #available(iOS 13.0, *) {
                    playButton.setBackgroundImage(UIImage(systemName: "play.circle.fill"), for: .normal)
                }
            }
        }
        else {
            q.play()
            if let _ = playButton {
                if #available(iOS 13.0, *) {
                    playButton.setBackgroundImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let c = player?.showModel?.mp3Array?.count {
            return c
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = modalPlayerTableView.dequeueReusableCell(withIdentifier: "ModalPlayerCell", for: indexPath) as? ModalPlayerTableViewCell,
            let mp3s = player?.showModel?.mp3Array
            else {
                print("no songs")
                return UITableViewCell() }
        
        if let title = mp3s[indexPath.row].title, let track = mp3s[indexPath.row].track {
            cell.textLabel?.text = track + " " + title
        }
        else {
            cell.textLabel?.text = "no song"
        }
        
        if let _ = mp3s[indexPath.row].destination {
            cell.accessoryType = .checkmark
        }
        else {
            cell.accessoryType = .none
        }

        return cell

    }
    

}
