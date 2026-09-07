//
//  CarPlaySceneDelegate.swift
//  Breaze
//
//  Created by Joseph Hardy on 1/10/21.
//  Copyright © 2021 Carquinez. All rights reserved.
//

import Foundation
import CarPlay

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?
    var templateManager: CarPlayTemplateManager?
    
    // CarPlay connected
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        // The head unit sends an automatic play on connect; only continue if we
        // were already playing when plugged in (paused stays paused)
        AudioPlayerArchive.shared.suppressAutoResumeOnConnect()
        // The template manager owns the CarPlay UI for the life of the connection
        self.templateManager = CarPlayTemplateManager(interfaceController: interfaceController)
        print("CarPlayTemplateManager initialized in scene delegate")
    }
    
    // CarPlay disconnected
    func sceneDidDisconnect(_ scene: UIScene) {
        // Unplugging pauses (and persists the stop point for the phone to pick up)
        AudioPlayerArchive.shared.pause()
        self.templateManager = nil
        self.interfaceController = nil
    }
}
