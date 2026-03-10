//
//  SceneDelegate.swift
//  ChateauArchive
//
//  Created by Joseph Hardy on 1/11/21.
//

import UIKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func sceneDidEnterBackground(_ scene: UIScene) {
        AudioPlayerArchive.shared.savePlaybackState()
    }
}
