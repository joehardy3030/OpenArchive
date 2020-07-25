//
//  ArchiveSuperViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/24/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit

class ArchiveSuperViewController: UIViewController {
    let archiveAPI = ArchiveAPI()
    let utils = Utils()
    let network = NetworkUtility()
    var showModel: ShowMetadataModel?
    var player: AudioPlayerArchive?
    var isPlaying = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? MiniPlayerViewController {
            player = AudioPlayerArchive()
            player?.showModel = self.showModel
          //  getDownloadedShow()
            if let p = player {
                vc.player = p
            }
        }
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
