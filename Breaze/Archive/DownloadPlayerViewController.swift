//
//  DownloadPlayerViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/19/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class DownloadPlayerViewController: UIViewController {
    //var identifier: String?
    //var showDate: String?
    let archiveAPI = ArchiveAPI()
    let utils = Utils()
    let network = NetworkUtility()
   // var mp3Array = [ShowMP3]()
    var showMetadata: ShowMetadataModel?
    var avPlayer: AudioPlayerArchive?
    var isPlaying = false
   // var isDownloaded = false
    // var playerQueue: AVQueuePlayer!
   // var playerItems = [AVPlayerItem]()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        //self.showTableView.delegate = self
        // self.showTableView.dataSource = self
        //self.navigationItem.title = showDate
        avPlayer = AudioPlayerArchive()
        getDownloadedShow()
    }
    
    func getDownloadedShow() {
         if let mp3s = self.showMetadata?.mp3Array {
             //self.mp3Array = mp3s
            loadAndPlay(mp3Array: mp3s)
         }
     }
    
    func loadAndPlay(mp3Array: [ShowMP3]) {
        //avPlayer?.playerQueue.removeAllItems()
        avPlayer?.loadQueuePlayer(tracks: mp3Array)
      //  print(avPlayer?.playerItems as Any)
        avPlayer?.play()
        avPlayer?.setupNotificationView()
      //  avPlayer?.playerQueue.addObserver(self, forKeyPath: "currentItem.loadedTimeRanges", options: .new, context: nil)
        //track player progress
        /*
        let interval = CMTime(value: 1, timescale: 2)
        
        avPlayer?.playerQueue.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { (progressTime) in
            
            let seconds = CMTimeGetSeconds(progressTime)
            let secondsString = String(format: "%02d", Int(seconds) % 60)
            let minutesString = String(format: "%02d", Int(seconds) / 60)
            self.currentTimeLabel.text = ("\(minutesString):\(secondsString)")
            if let duration = self.avPlayer.playerQueue.currentItem?.duration {
                let totalSeconds = CMTimeGetSeconds(duration)
                self.audioLengthSlider.value = Float(seconds/totalSeconds)
            }
        }
        */
    }
    
    func trackURLfromName(name: String?) -> URL? {
        guard let d = utils.getDocumentsDirectory(), let n = name else { return nil }
        let url = d.appendingPathComponent(n)
        return url
    }

    
}
