//
//  ArchiveSuperViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/24/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit

class ArchiveSuperViewController: UIViewController {
    var miniPlayer: MiniPlayerViewController?
    var showModel: ShowMetadataModel?
    var player: AudioPlayerArchive?
    var isPlaying = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
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

}


extension ArchiveSuperViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        print("called this")
        if let vc = viewController as? ArchiveSuperViewController {
            vc.player = self.player
        }
    }
}
