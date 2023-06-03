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
    let notificationCenter: NotificationCenter = .default
    let commandCenter = MPRemoteCommandCenter.shared()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.modalPlayerTableView.delegate = self
        self.modalPlayerTableView.dataSource = self
        notificationCenter.addObserver(self, selector: #selector(playbackDidStart), name: .playbackStarted, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackDidPause), name: .playbackPaused, object: self.player.playerQueue)
        setupCommandCenter()
        initialDefaults()
        setupShow()
    }
    
    // Try "deint" vs viewWillDisappear
    override func viewWillDisappear(_ animated: Bool) {
        notificationCenter.removeObserver(self, name: .playbackStarted, object: nil)
        notificationCenter.removeObserver(self, name: .playbackPaused, object: self.player.playerQueue)
    }
    
    @IBAction func playButton(_ sender: Any) {
        playPause()
    }

    @IBAction func forwardButton(_ sender: Any) {
        if let q = player.playerQueue {
            q.advanceToNextItem()
        }
    }
    
    @IBAction func backButton(_ sender: Any) {
        rewindFunctionality()
    }
    
    func rewindFunctionality() {
        // This operation should probably belong to the player class
        let index = player.getCurrentTrackIndex()
        if let mp3s = self.player.showMetadataModel?.mp3Array {
            player.loadQueuePlayer(tracks: mp3s)
         }
        if let mp = self.getMiniPlayerController() {
            mp.setupShow()
        }

        initialDefaults()
        setupShow()
        player.rewindToPreviousItem(index: index)
        
    }
    
    func setupCommandCenter() {
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            rewindFunctionality()
            //self.rewindToPreviousItem(index: 0)
            return .success
        }
    }
    
    @objc func handleSliderChange() {
        self.player.timerSliderHandler(timerValue: timerSlider.value)
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
        guard let _ = player.playerQueue else { return }
        playPauseButtonImageSetup()
        //player?.playerQueue?.addObserver(self, forKeyPath: "currentItem.loadedTimeRanges", options: .new, context: nil)
        self.player.playerQueue?.addObserver(self, forKeyPath: "currentItem.status", options: .new, context: nil)
        player.setupTimer()  { (seconds: Double?) -> Void in
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
        player.songDetailsModel.songDetailsFromMetadata(row: player.getCurrentTrackIndex(), showModel: player.showMetadataModel)
        songLabel.text = player.songDetailsModel.name
        dateLabel.text = player.songDetailsModel.date
        venueLabel.text = player.songDetailsModel.venue
    }    
   
    func selectCurrentTrack() {
        let index = player.getCurrentTrackIndex()
        let indexPath = IndexPath(item: index, section: 0)
        self.modalPlayerTableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableView.ScrollPosition.middle)
    }
    
    func timerCallback(seconds: Double?) {
        self.currentTimeLabel.text = utils.getTimerString(seconds: seconds)
        self.totalTimeLabel.text = self.player.getCurrentTrackTotalTimeString()
        if let duration = self.player.playerQueue?.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            self.timerSlider.value = Float((seconds ?? 0.0)/(totalSeconds ))
        }
    }
    
    func playPauseButtonImageSetup() {
        guard let q = player.playerQueue else { return }
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
        guard let q = player.playerQueue else { return }
        if q.rate > 0.0 {
            player.pause()
        }
        else {
            player.play()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let c = player.showMetadataModel?.mp3Array?.count {
            return c
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = modalPlayerTableView.dequeueReusableCell(withIdentifier: "ModalPlayerCell", for: indexPath) as? ModalPlayerTableViewCell,
            let mp3s = player.showMetadataModel?.mp3Array
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

private extension ModalPlayerViewController {
    @objc private func playbackDidStart(_ notification: Notification) {
        guard let _ = playButton else { return }
        if #available(iOS 13.0, *) {
            playButton.setBackgroundImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
        }
        print("Item playing -- modal player")
    }
    
    @objc private func playbackDidPause(_ notification: Notification) {
        guard let _ = playButton else { return }
        if #available(iOS 13.0, *) {
            playButton.setBackgroundImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        }
        print("Item paused -- modal player ")
    }
}
