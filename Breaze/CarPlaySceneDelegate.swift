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
        AudioPlayerArchive.log.notice("CarPlay connected")
        // The template manager owns the CarPlay UI for the life of the connection
        self.templateManager = CarPlayTemplateManager(interfaceController: interfaceController)
        print("CarPlayTemplateManager initialized in scene delegate")
    }
    
    // The Swift name keeps the "InterfaceController" suffix here (unlike didConnect);
    // a `didDisconnect:` spelling compiles but is never called.
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        disconnectCarPlay()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        disconnectCarPlay()
    }

    private func disconnectCarPlay() {
        // CarPlay and UIScene may both notify us. Don't pause a phone session
        // the user has resumed after the first callback.
        guard interfaceController != nil else { return }
        AudioPlayerArchive.shared.handleCarPlayDisconnect()
        self.templateManager = nil
        self.interfaceController = nil
    }
}
