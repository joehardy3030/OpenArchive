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
        // Hand a reference to the interface controller to CarPlayDownloadsTemplate
        self.templateManager = CarPlayTemplateManager(interfaceController: interfaceController)
        print("CarPlayTemplateManager initialized in scene delegate")
    }
    
    // CarPlay disconnected
    func sceneDidDisconnect(_ scene: UIScene) {
        self.templateManager = nil
        self.interfaceController = nil
    }
}
