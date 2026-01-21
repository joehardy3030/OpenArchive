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
        // Layout is handled by storyboard - no programmatic changes for now
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let _ = segue.destination as? ArchiveTabBarController {
            // TabBarController setup
        }
        
        if let mp = segue.destination as? MiniPlayerViewController {
            mp.player = player
            self.miniPlayerVC = mp
        }
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
}
