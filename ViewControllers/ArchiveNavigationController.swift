//
//  DownloadsNavigationController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/26/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit

class ArchiveNavigationController: UINavigationController {
    var player: AudioPlayerArchive?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        distributePlayer()
        //navigationController?.delegate = self
        // Do any additional setup after loading the view.
    }
    
    
    func distributePlayer() {
        if let tvc = self.topViewController as? ArchiveSuperViewController {
            tvc.player = self.player
        }
    }

}
