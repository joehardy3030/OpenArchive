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
    
    /// Layout: Tab bar at very bottom, mini player above tab bar, content above mini player
    private func fixContainerViewLayout() {
        // Find the two container views
        var miniContainer: UIView?
        var tabContainer: UIView?
        
        for subview in view.subviews {
            let hasHeightConstraint = subview.constraints.contains { constraint in
                constraint.firstAttribute == .height && constraint.constant == 120
            }
            if hasHeightConstraint {
                miniContainer = subview
            } else if subview.translatesAutoresizingMaskIntoConstraints == false {
                tabContainer = subview
            }
        }
        
        guard let tabContainerView = tabContainer,
              let miniContainerView = miniContainer else {
            print("StartViewController: Could not find container views")
            return
        }
        
        // Deactivate existing bottom constraints for both containers
        for constraint in view.constraints {
            let isBottomConstraint = constraint.firstAttribute == .bottom || constraint.secondAttribute == .bottom
            let involvesTab = (constraint.firstItem as? UIView == tabContainerView) || (constraint.secondItem as? UIView == tabContainerView)
            let involvesMini = (constraint.firstItem as? UIView == miniContainerView) || (constraint.secondItem as? UIView == miniContainerView)
            
            if isBottomConstraint && (involvesTab || involvesMini) {
                constraint.isActive = false
            }
        }
        
        // Tab container goes to the bottom of the view (so tab bar is at very bottom)
        tabContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        // Mini player positioned above the tab bar
        // Tab bar is approximately 49 points, plus safe area inset on newer devices
        let tabBarHeight: CGFloat = 83 // 49 + typical safe area bottom on modern iPhones
        miniContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -tabBarHeight).isActive = true
        
        // Bring mini player to front
        view.bringSubviewToFront(miniContainerView)
        
        print("StartViewController: Layout set - tab bar at bottom, mini player above it")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tabBarController = segue.destination as? ArchiveTabBarController {
            // Add bottom inset so TabBarController content leaves room for mini player
            let miniPlayerHeight: CGFloat = 120
            tabBarController.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: miniPlayerHeight, right: 0)
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
