//
//  DownloadsNavigationController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/26/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit

class ArchiveNavigationController: UINavigationController {
    let player = AudioPlayerArchive.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        print("ArchiveNavigationController")
        //navigationController?.delegate = self
        // Do any additional setup after loading the view.
    }
}
