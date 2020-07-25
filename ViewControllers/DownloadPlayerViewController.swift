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
    var miniPlayer: MiniPlayerViewController?
    var showModel: ShowMetadataModel?
    var player: AudioPlayerArchive?
    var isPlaying = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        //self.showTableView.delegate = self
        // self.showTableView.dataSource = self
        if let m = player?.showModel {
            self.navigationItem.title = m.metadata?.date
        }
        //DispatchQueue.main.async{
        //}
     //   getDownloadedShow()
     //   miniPlayer?.player = self.player
        navigationController?.delegate = self
    }

    func getDownloadedShow() {
         if let mp3s = self.showModel?.mp3Array {
            player?.loadQueuePlayer(tracks: mp3s)
         }
     }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let miniPlayer = segue.destination as? MiniPlayerViewController {
            player = AudioPlayerArchive()
            player?.showModel = self.showModel
            getDownloadedShow()
            if let p = player {
                miniPlayer.player = p
            }
        }
    }
        
}

extension DownloadPlayerViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        print("called this")
        if let vc = viewController as? DownloadsViewController {
            vc.player = self.player
        }
    }
}
