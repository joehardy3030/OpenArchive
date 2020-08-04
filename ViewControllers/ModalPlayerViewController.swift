//
//  ModalPlayerViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 8/2/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit

class ModalPlayerViewController: ArchiveSuperViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var modalPlayerTableView: UITableView!
    var timer: ArchiveTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.modalPlayerTableView.delegate = self
        self.modalPlayerTableView.dataSource = self
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupPlayer()
        timer?.setupTimer()  { (seconds: Double?, totalSeconds: Double?) -> Void in
            self.timerCallback(seconds: seconds, totalSeconds: totalSeconds)
        }
                   
       // print(player)
    }

    @IBAction func forwardButton(_ sender: Any) {
        if let q = player?.playerQueue {
            q.advanceToNextItem()
        }
    }
    
    @IBAction func playButton(_ sender: Any) {
        playPause()
    }
        
    func setupPlayer() {
        playPauseButtonImageSetup()
    }
    
    func timerCallback(seconds: Double?, totalSeconds: Double?) {
        //  print("\(String(describing: seconds)):\(String(describing: totalSeconds))")
        let secondsString = String(format: "%02d", Int(seconds ?? 0) % 60)
        let minutesString = String(format: "%02d", Int(seconds ?? 0) / 60)
        self.currentTimeLabel.text = ("\(minutesString):\(secondsString)")
        
        let totalSecondsString = String(format: "%02d", Int(totalSeconds ?? 0) % 60)
        let totalMinutesString = String(format: "%02d", Int(totalSeconds ?? 0) / 60)
        self.totalTimeLabel.text = ("\(totalSecondsString):\(totalMinutesString)")
    }
    
    func playPauseButtonImageSetup() {
        guard let q = player?.playerQueue else { return }
        if q.rate > 0.0 {
            if let _ = playButton {
                if #available(iOS 13.0, *) {
                    playButton.setBackgroundImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
                }
            }
        //    isPlaying = false
        }
        else {
            if let _ = playButton {
                if #available(iOS 13.0, *) {
                    playButton.setBackgroundImage(UIImage(systemName: "play.circle.fill"), for: .normal)
                }
            }
         //   isPlaying = true
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
        //    isPlaying = false
        }
        else {
            q.play()
            if let _ = playButton {
                if #available(iOS 13.0, *) {
                    playButton.setBackgroundImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
                }
            }
         //   isPlaying = true
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let c = player?.showModel?.mp3Array?.count {
            print(c)
            return c
        }
        else {
            print(player?.showModel?.mp3Array?[0])
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
