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
    
    // CarPlay connected
    @available(iOS 13.0, *)
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        // Hand a reference to the interface controller to CarPlayDownloadsTemplate
        _ = CarPlayDownloadsTemplate(interfaceController: interfaceController)
    }
    
    // CarPlay disconnected
    @available(iOS 13.0, *)
    private func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnect interfaceController: CPInterfaceController) {
        self.interfaceController = nil
    }
}
