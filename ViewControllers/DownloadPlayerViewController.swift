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

class DownloadPlayerViewController: ArchiveSuperViewController { //UIViewController {
    let archiveAPI = ArchiveAPI()
    let utils = Utils()
    let network = NetworkUtility()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        if let m = player?.showModel {
            self.navigationItem.title = m.metadata?.date
        }
        getDownloadedShow()  // viewDidLoad is called after segue, so need to do this here
        miniPlayer?.newShow()
        navigationController?.delegate = self
    }
    

    func getDownloadedShow() {
        if let mp3s = self.player?.showModel?.mp3Array {
            if (player?.playerItems.count)! > 0 {
                player?.playerItems = [AVPlayerItem]()
            }
            player?.loadQueuePlayer(tracks: mp3s)
         }
     }
        
}
