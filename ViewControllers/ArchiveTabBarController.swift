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
        
        // Force classic tab bar style (iOS 18+ uses a new floating/pill-shaped design by default)
        if #available(iOS 18.0, *) {
            mode = .tabBar  // Use classic bottom tab bar instead of new floating style
        }
    }
}
