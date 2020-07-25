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
  //  var miniPlayer: MiniPlayerViewController?
   // var showModel: ShowMetadataModel?
  //  var player: AudioPlayerArchive?
  //  var isPlaying = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        //self.showTableView.delegate = self
        // self.showTableView.dataSource = self
        if let m = player?.showModel {
            self.navigationItem.title = m.metadata?.date
        }
        getDownloadedShow()  // viewDidLoad is called after segue, so need to do this here
        miniPlayer?.newShow() //
        navigationController?.delegate = self
    }

    func getDownloadedShow() {
         if let mp3s = self.showModel?.mp3Array {
            player?.loadQueuePlayer(tracks: mp3s)
            //miniPlayer?.player = player
         }
     }
    /*
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let mp = segue.destination as? MiniPlayerViewController {
            self.miniPlayer = mp
            player = AudioPlayerArchive()
            player?.showModel = self.showModel
            if let p = player {
                mp.player = p
            }
        }
    }
    */
        
}

extension DownloadPlayerViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        print("called this")
        if let vc = viewController as? DownloadsViewController {
            vc.player = self.player
        }
    }
}
