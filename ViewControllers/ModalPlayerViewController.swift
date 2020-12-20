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
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //setupShow()
        
       // print(player)
    }

    override func viewWillDisappear(_ animated: Bool) {
        // give it a reference to mp and then give the timer back to the mp
    }

    @IBAction func forwardButton(_ sender: Any) {
        if let q = player?.playerQueue {
            q.advanceToNextItem()
        }
    }
    
    @objc func handleSliderChange() {
        if let duration = self.player?.playerQueue?.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            let value = Float64(timerSlider.value) * totalSeconds
            let seekTime = CMTime(value: Int64(value), timescale: 1)
            self.player?.playerQueue?.seek(to: seekTime, completionHandler: { (completedSeek) in
            })
        }
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

    func setupShow() {
        setupPlayer()
        timer?.setupTimer()  { (seconds: Double?) -> Void in
             self.timerCallback(seconds: seconds)
        }
       // print(timer)
        setupSlider()
        setupSong()
    }
    
    func initialDefaults() {
        dateLabel.text = ""
        songLabel.text = ""
        venueLabel.text = ""
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
     
    func setupSlider() {
        if let ts = timerSlider {
            ts.value = 0.0
            ts.addTarget(self, action: #selector(handleSliderChange), for: .valueChanged)
        }
    }
    
    func setupPlayer() {
        playPauseButtonImageSetup()
        player?.playerQueue?.addObserver(self, forKeyPath: "currentItem.loadedTimeRanges", options: .new, context: nil)
    }
    
   
    func selectCurrentTrack() {
        guard let index = player?.getCurrentTrackIndex() else { return }
        let indexPath = IndexPath(item: index, section: 0)
        self.modalPlayerTableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableView.ScrollPosition.middle)

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
    
    func timerCallback(seconds: Double?) {
        let secondsString = String(format: "%02d", Int(seconds ?? 0) % 60)
        let minutesString = String(format: "%02d", Int(seconds ?? 0) / 60)
        self.currentTimeLabel.text = ("\(minutesString):\(secondsString)")
        self.currentItemTotalTime()
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
