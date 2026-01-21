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
        
        // Use transform to visually push the tab bar down
        // Adjust this value: positive moves down, negative moves up
        let offsetDown: CGFloat = 20
        tabBar.transform = CGAffineTransform(translationX: 0, y: offsetDown)
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }
}
