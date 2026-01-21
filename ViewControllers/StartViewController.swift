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
    
    /// Fix the overlapping container views by adjusting constraints programmatically
    private func fixContainerViewLayout() {
        // Find the two container views (they are the only direct subviews that are container views)
        let containerViews = view.subviews.filter { $0 is UIView && $0.subviews.isEmpty == false }
        
        // The mini player container has a fixed height of 120
        // The tab bar container is the larger one
        for subview in view.subviews {
            // Check for mini player container (has height constraint of 120)
            let hasHeightConstraint = subview.constraints.contains { constraint in
                constraint.firstAttribute == .height && constraint.constant == 120
            }
            if hasHeightConstraint {
                miniPlayerContainerView = subview
            } else if subview != miniPlayerContainerView && subview.translatesAutoresizingMaskIntoConstraints == false {
                // The other container view (tab bar controller)
                tabBarContainerView = subview
            }
        }
        
        guard let tabContainer = tabBarContainerView,
              let miniContainer = miniPlayerContainerView else {
            print("StartViewController: Could not find container views for layout fix")
            return
        }
        
        // Find and deactivate the tab container's bottom-to-safeArea constraint
        for constraint in view.constraints {
            // Look for constraint: tabContainer.bottom = safeArea.bottom
            if (constraint.firstItem as? UIView == tabContainer && constraint.firstAttribute == .bottom) ||
               (constraint.secondItem as? UIView == tabContainer && constraint.secondAttribute == .bottom) {
                if constraint.firstItem is UILayoutGuide || constraint.secondItem is UILayoutGuide {
                    constraint.isActive = false
                    print("StartViewController: Deactivated tab container bottom constraint to safe area")
                    break
                }
            }
        }
        
        // Add new constraint: tabContainer.bottom = miniContainer.top
        tabContainer.bottomAnchor.constraint(equalTo: miniContainer.topAnchor).isActive = true
        print("StartViewController: Added tab container bottom to mini player top constraint")
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
