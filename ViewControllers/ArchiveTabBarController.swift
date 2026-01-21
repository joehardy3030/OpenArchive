//
//  ArchiveTabBarController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/26/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit

class ArchiveTabBarController: UITabBarController {
    var player: AudioPlayerArchive?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 18.0, *) {
            mode = .tabBar
        }
        
        configureTabBarAppearance()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Move the tab bar lower - closer to the bottom of the screen
        // Adjust this value to move it lower (positive) or higher (negative)
        let offsetDown: CGFloat = 10
        
        var tabBarFrame = tabBar.frame
        tabBarFrame.origin.y = view.bounds.height - tabBarFrame.height - view.safeAreaInsets.bottom + offsetDown
        tabBar.frame = tabBarFrame
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }
}
