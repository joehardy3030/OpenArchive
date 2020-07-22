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
    let archiveAPI = ArchiveAPI()
    let utils = Utils()
    let network = NetworkUtility()
    var showModel: ShowMetadataModel?
    var player: AudioPlayerArchive?
    var isPlaying = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        //self.showTableView.delegate = self
        // self.showTableView.dataSource = self
        navigationController?.delegate = self
        if let m = showModel {
            self.navigationItem.title = m.metadata?.date
        }
        player = AudioPlayerArchive()
        getDownloadedShow()
    }
    
    func getDownloadedShow() {
         if let mp3s = self.showModel?.mp3Array {
            loadAndPlay(mp3Array: mp3s)
         }
     }
    
    func loadAndPlay(mp3Array: [ShowMP3]) {
        player?.loadQueuePlayer(tracks: mp3Array)
        player?.play()
        player?.setupNotificationView()
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? MiniPlayerViewController {
            if let m = showModel {
                vc.showModel = m
            }
        }
    }
        
}


extension DownloadPlayerViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        print("called this")
        if let vc = viewController as? DownloadsViewController {
            vc.player = self.player
            print("Made it here")
        }
    }
}
