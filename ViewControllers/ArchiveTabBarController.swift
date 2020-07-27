//
//  ArchiveTabBarController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/26/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit

class ArchiveTabBarController: UITabBarController {
    var player: AudioPlayerArchive?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        distributePlayer()
        // Do any additional setup after loading the view.
    }
    
    func distributePlayer() {
        if let vcs = self.viewControllers {
            for vc in vcs {
                if let avc = vc as? ArchiveNavigationController {
                    avc.player = self.player
                    print(avc.player)
                }
            }
        }
    }
    
}
