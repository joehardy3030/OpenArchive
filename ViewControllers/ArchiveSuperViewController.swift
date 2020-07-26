//
//  ArchiveSuperViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/24/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit

class ArchiveSuperViewController: UIViewController {
    let network = NetworkUtility()
    let utils = Utils()
    var prevController: ArchiveSuperViewController?
    var miniPlayer: MiniPlayerViewController?
    var player: AudioPlayerArchive?
    var isPlaying = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if let mp = segue.destination as? MiniPlayerViewController {
                self.miniPlayer = mp
                if let p = player {
                    mp.player = p
                }
            }
    }

}


extension ArchiveSuperViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        print("called this")
        if let vc = viewController as? ArchiveSuperViewController {
            vc.prevController = self
        }
    }
}
