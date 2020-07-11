//
//  ShowViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/4/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class ShowViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var audioLengthSlider: UISlider!
    @IBOutlet weak var audioLengthLabel: UILabel!
    @IBOutlet weak var reverseButton: UIImageView!
    @IBOutlet weak var playPauseButton: UIImageView!
    @IBOutlet weak var forwardButton: UIImageView!
    @IBOutlet weak var showTableView: UITableView!
    var identifier: String?
    let archiveAPI = ArchiveAPI()
    let avPlayer = AudioPlayerArchive()
    var mp3Array = [ShowMP3]()
    var showMetadata: ShowMetadataModel!
    let utils = Utils()
    let playerViewController = AVPlayerViewController()
    var isPlaying = false
    var kvContext = 0x0
    
    override func viewDidLoad() {

        super.viewDidLoad()
        self.showTableView.delegate = self
        self.showTableView.dataSource = self
        setupPlayer()
        getIAGetShow()
        utils.getMemory()
    }
    
    @IBAction func clickPlayButton(_ sender: Any) {
        playPause()
    }
    @IBAction func clickForwardButton(_ sender: Any) {
        self.avPlayer.playerQueue.advanceToNextItem()
    }
    
    func setupPlayer() {
        
    }
    
    func playPause() {
        if self.avPlayer.playerQueue.rate > 0.0 {
            self.avPlayer.pause()
        }
        else {
            self.avPlayer.play()
        }
    }
    
    /*
    let audioLengthLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textColor = .white
        return label
    }()
    */
    
    func getIAGetShow() {
        
        guard let id = self.identifier else { return }
        let url = archiveAPI.metadataURL(identifier: id)
    
        archiveAPI.getIARequestMetadata(url: url) {
            (response: ShowMetadataModel) -> Void in
            
            self.showMetadata = response
            if let files = self.showMetadata?.files {
                for f in files {
                    if (f.format?.contains("MP3"))! {
                        print(f.format as Any)
                        let showMP3 = ShowMP3(identifier: self.identifier, name: f.name, title: f.title, track: f.track)
                        self.mp3Array.append(showMP3)
                    }
                }
            }
            
            self.downloadShow()
            
            DispatchQueue.main.async{
                self.showTableView.reloadData()
                print(self.showMetadata.files_count as Any)
            }
        }
    }
    
    func downloadShow() {
        for f in self.mp3Array {
            let url = archiveAPI.downloadURL(identifier: self.identifier, filename: f.name)
            archiveAPI.getIADownload(url: url) {
                (response: URL?) -> Void in
                DispatchQueue.main.async{
                    self.setDownloadComplete(destination: response, name: f.name)
                    print(response)
                   // if let url = response {
                   //     self.avPlayer.prepareToPlay(url: url)
                        //self.avPlayer.playerItems.append(item!)
                   // }
                    self.showTableView.reloadData()
                }
            }
        }
    }
    
    func setDownloadComplete(destination: URL?, name: String?) {
        var counter = 0
        if let d = destination {
            for i in 0...(self.mp3Array.count - 1) {
                if self.mp3Array[i].name == name {
                    self.mp3Array[i].destination = d
                }
                if self.mp3Array[i].destination != nil {
                    counter += 1
                }
            }
            if self.mp3Array.count == counter {
                self.avPlayer.loadQueuePlayer(tracks: self.mp3Array)
                self.avPlayer.play()
                self.avPlayer.playerQueue.addObserver(self, forKeyPath: "currentItem.loadedTimeRanges", options: .new, context: nil)
               // self.present(avPlayer.playerViewController, animated: true)
            }
        }
    }
 
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "currentItem.loadedTimeRanges" {
            isPlaying = true
            print(isPlaying)
            if let duration = self.avPlayer.playerQueue.currentItem?.duration {
                let seconds = CMTimeGetSeconds(duration)
                if seconds > 0 && seconds < 100000000.0 {
                    let secondsText =  Int(seconds) % 60
                    //let minutesText = Int(seconds) / 60
                    let minutesText = String(format: "%02d", Int(seconds) / 60)
                    audioLengthLabel.text = "\(minutesText):\(secondsText)"
                    print(secondsText)
                }
            }
        }

    }

    /*
    self.present(playerViewController, animated: true) {
          if let avp = self.avPlayer {
              avp.play()
          }
      }
    */
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mp3Array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = showTableView.dequeueReusableCell(withIdentifier: "ShowCell", for: indexPath) as! ShowTableViewCell
        
        if let title = self.mp3Array[indexPath.row].title, let track = self.mp3Array[indexPath.row].track {
            cell.songLabel.text = track + " " + title
        }
        else {
            cell.songLabel.text = "no song"
        }
        
        if let _ = self.mp3Array[indexPath.row].destination {
            cell.accessoryType = .checkmark
        }
        else {
            cell.accessoryType = .none
        }

        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //if let cell = yearTableView.cellForRow(at: indexPath as IndexPath) {
        self.playPause()        
    }

}
