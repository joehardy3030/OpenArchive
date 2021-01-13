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
        
        let item = CPListItem(text: "My title", detailText: "My subtitle")
        //item.listItemHandler = { item, completion, [weak self] in
         // Start playback asynchronously…
        // self.interfaceController.pushTemplate(CPNowPlayingTemplate.shared(), animated: true)
        // completion()
        //}
        let section = CPListSection(items: [item])
        let listTemplate = CPListTemplate(title: "Albums", sections: [section])
        interfaceController.setRootTemplate(listTemplate, animated: true)
        //self.interfaceController?.pushTemplate(listTemplate, animated: true)
        //let listTemplate: CPListTemplate = CPListTemplate()
    }
    // CarPlay disconnected
    @available(iOS 13.0, *)
    private func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnect interfaceController: CPInterfaceController) {
        self.interfaceController = nil
    }
}
