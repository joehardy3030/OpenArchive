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
    
    // Container views for programmatic constraint adjustment
    private weak var tabBarContainerView: UIView?
    private weak var miniPlayerContainerView: UIView?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Find the container views and fix layout constraints
        fixContainerViewLayout()
    }
    
    /// Fix the layout: tab bar at bottom, mini player above tab bar, content above mini player
    private func fixContainerViewLayout() {
        // Find the two container views
        for subview in view.subviews {
            // Check for mini player container (has height constraint of 120)
            let hasHeightConstraint = subview.constraints.contains { constraint in
                constraint.firstAttribute == .height && constraint.constant == 120
            }
            if hasHeightConstraint {
                miniPlayerContainerView = subview
            } else if subview != miniPlayerContainerView && subview.translatesAutoresizingMaskIntoConstraints == false {
                tabBarContainerView = subview
            }
        }
        
        guard let tabContainer = tabBarContainerView,
              let miniContainer = miniPlayerContainerView else {
            print("StartViewController: Could not find container views for layout fix")
            return
        }
        
        // Deactivate existing bottom constraints for both containers
        for constraint in view.constraints {
            let isTabContainerBottom = (constraint.firstItem as? UIView == tabContainer && constraint.firstAttribute == .bottom) ||
                                       (constraint.secondItem as? UIView == tabContainer && constraint.secondAttribute == .bottom)
            let isMiniContainerBottom = (constraint.firstItem as? UIView == miniContainer && constraint.firstAttribute == .bottom) ||
                                        (constraint.secondItem as? UIView == miniContainer && constraint.secondAttribute == .bottom)
            
            if isTabContainerBottom || isMiniContainerBottom {
                constraint.isActive = false
            }
        }
        
        // New layout (bottom to top): Tab bar -> Mini player -> Content
        // 1. Tab container goes all the way to the bottom (so its tab bar is at the very bottom)
        tabContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        // 2. Mini player sits above the tab bar (49 points is standard tab bar height)
        let tabBarHeight: CGFloat = 49
        miniContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -tabBarHeight).isActive = true
        
        print("StartViewController: Layout adjusted - tab bar at bottom, mini player above it")
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
        if let tabBarController = segue.destination as? ArchiveTabBarController {
            // Add additional safe area inset so content views leave room for the mini player above the tab bar
            let miniPlayerHeight: CGFloat = 120
            tabBarController.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: miniPlayerHeight, right: 0)
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
