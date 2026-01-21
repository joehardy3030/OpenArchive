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
    
    @IBOutlet weak var miniPlayerBottomConstraint: NSLayoutConstraint?
    
    private weak var miniPlayerVC: MiniPlayerViewController?
    private weak var tabBarControllerRef: ArchiveTabBarController?
    private var hasAttemptedRestore = false
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Layout is handled by storyboard - no programmatic changes for now
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateMiniPlayerBottomConstraint()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tab = segue.destination as? ArchiveTabBarController {
            tabBarControllerRef = tab
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

    private func updateMiniPlayerBottomConstraint() {
        guard let constraint = miniPlayerBottomConstraint,
              let tabController = tabBarControllerRef else { return }

        // Convert tab bar's top edge into StartViewController coordinate space.
        let tabBarFrameInStartView = tabController.tabBar.convert(tabController.tabBar.bounds, to: view)
        let tabBarTopY = tabBarFrameInStartView.minY
        let safeAreaBottomY = view.safeAreaLayoutGuide.layoutFrame.maxY

        // Positive constant means mini player sits above the safe area bottom.
        let desiredConstant = max(0, safeAreaBottomY - tabBarTopY)
        if abs(constraint.constant - desiredConstant) > 0.5 {
            constraint.constant = desiredConstant
            view.layoutIfNeeded()
        }
    }
}
