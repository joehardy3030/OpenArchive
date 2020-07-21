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
    var identifier: String?
    var showDate: String?
    let archiveAPI = ArchiveAPI()
    let utils = Utils()
    let network = NetworkUtility()
   // var mp3Array = [ShowMP3]()
    var showMetadata: ShowMetadataModel?
    var avPlayer: AudioPlayerArchive?
    var isPlaying = false
    var isDownloaded = false
    var playerQueue: AVQueuePlayer!
    var playerItems = [AVPlayerItem]()
    let trackName = "gd88-10-01d1t08.mp3"
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        //self.showTableView.delegate = self
        // self.showTableView.dataSource = self
        //getAllTheMP3s()
        //self.navigationItem.title = showDate
        //getDownloadedShow()
        avPlayer = AudioPlayerArchive()
        getDownloadedShow()
        //playFromName(name: trackName)
        //playerQueue.play()
    }
    
    func getAllTheMP3s() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            for f in fileURLs {
                prepareToPlay(url: f)
            }
            playerQueue = AVQueuePlayer(items: playerItems)
            print(fileURLs)
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
    }
    
    func getDownloadedShow() {
         if let mp3s = self.showMetadata?.mp3Array {
             //self.mp3Array = mp3s
            loadAndPlay(mp3Array: mp3s)
         }
     }
    
    func prepareToPlay(url: URL) {
        let asset = AVAsset(url: url)
        let assetKeys = ["playable"]
        let item = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: assetKeys)
        playerItems.append(item)
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
    
    func playFromName(name: String?) {
        //guard let d = utils.getDocumentsDirectory(), let n = name else { return }
       // let url = d.appendingPathComponent(n)
        guard let n = name, let url = trackURLfromName(name: n) else { return }
        prepareToPlay(url: url)
        playerQueue = AVQueuePlayer(items: playerItems)
        playerQueue.play()
    }
    
}
