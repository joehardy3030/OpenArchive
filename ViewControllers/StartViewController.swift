//
//  StartViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/26/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
//import FirebaseUI

class StartViewController: ArchiveSuperViewController {
    
    private weak var miniPlayerVC: MiniPlayerViewController?
    private var hasAttemptedRestore = false
        
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Attempt to restore playback state after view hierarchy is set up
        // Only do this once on initial launch
        if !hasAttemptedRestore, let mp = miniPlayerVC {
            hasAttemptedRestore = true
            mp.attemptRestorePlaybackState()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ArchiveTabBarController {
           // if let p = player {
           //     vc.player = p // There needs to be a player already for this to work. Need to inject it.
           // }
        }
        
        if let mp = segue.destination as? MiniPlayerViewController {
            mp.player = player // There needs to be a player already for this to work. Need to inject it.
            self.miniPlayerVC = mp // Keep reference for restore
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
