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
        
        if #available(iOS 18.0, *) {
            mode = .tabBar
        }
    }
}
