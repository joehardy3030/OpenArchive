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
    let archiveAPI = ArchiveAPI()
    var prevController: ArchiveSuperViewController?
    var miniPlayer: MiniPlayerViewController?
    var player: AudioPlayerArchive?
    var isPlaying = false

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
    }
    
    /*
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if let mp = segue.destination as? MiniPlayerViewController {
                self.miniPlayer = mp
                print("Set the miniplayer")
                if let p = player {
                    mp.player = p // There needs to be a player already for this to work. Need to inject it.
                }
            }
    }
    */

}


extension ArchiveSuperViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
       // print("called this")
        if let _ = viewController as? ArchiveSuperViewController {
            // vc.miniPlayer?.player = player
            //  vc.prevController = self
        }
    }
}
