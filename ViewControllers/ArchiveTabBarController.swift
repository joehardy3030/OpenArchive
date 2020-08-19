//
//  ArchiveTabBarController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/26/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import Firebase

class ArchiveTabBarController: UITabBarController {
    var player: AudioPlayerArchive?
    var db: Firestore!

    override func viewDidLoad() {
        super.viewDidLoad()
        injectDependencies()
        // Do any additional setup after loading the view.
    }
    
    func injectDependencies() {
        if let vcs = self.viewControllers {
            for vc in vcs {
                if let avc = vc as? ArchiveNavigationController {
                    avc.player = self.player
                    avc.db = self.db
                }
            }
        }
    }
}
