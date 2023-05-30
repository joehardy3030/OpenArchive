//
//  CarPlayDownloadsTemplate.swift
//  Breaze
//
//  Created by Joseph Hardy on 1/13/21.
//  Copyright © 2021 Carquinez. All rights reserved.
//

import UIKit
import AVFoundation
import CarPlay
import Firebase
import FirebaseFirestore
import MediaPlayer


@available(iOS 14.0, *)
class CarPlayTemplateManager: NSObject, CPInterfaceControllerDelegate {

    let interfaceController: CPInterfaceController?
    var player: AudioPlayerArchive?
    var auth: Auth?
    var network: NetworkUtility!
    var db: Firestore!
    var isPlaying = false
    fileprivate(set) var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    let decades = ["1960s", "1970s", "1980s", "1990s"]
    let years = ["0","1","2","3","4","5","6","7","8","9"]
    let commandCenter = MPRemoteCommandCenter.shared()
    
    init(interfaceController: CPInterfaceController?) {
        self.interfaceController = interfaceController
        super.init()
        self.interfaceController?.delegate = self
        self.db = Firestore.firestore()
        self.player = AudioPlayerArchive.shared
        self.network = NetworkUtility(db: db)
        self.decadesCPListTemplate()
    }
    
    func numberOfChildItems(at indexPath: IndexPath) -> Int {
        return 0
    }
    
    private func decadesCPListTemplate() {
        var items = [CPListItem]()
        
        for d in decades {
            let item = CPListItem(text: d, detailText: "")
            item.handler = { item, completion in
                print("Clicked")
                _ = CarPlayDownloadsTemplate(interfaceController: self.interfaceController, decade: item.text)
                completion()
            }
            items.append(item)
        }
                
        let section = CPListSection(items: items)
        let decadesTemplate = CPListTemplate(title: "Decades", sections: [section])
        self.interfaceController?.setRootTemplate(decadesTemplate, animated: true)
    }
    
    
    private func yearsCPListTemplate(decade: String?) -> CPListTemplate {
        var items = [CPListItem]()
        var yearPrefix: String
        
        if let t = decade {
            print(t)
            switch t {
            case "1960s":
                yearPrefix = "196"
            case "1970s":
                yearPrefix = "197"
            case "1980s":
                yearPrefix = "198"
            case "1990s":
                yearPrefix = "199"
            default:
                yearPrefix = "200"
            }
        }
        else {
            yearPrefix = "202"
        }
        
        for y in years {
            let item = CPListItem(text: yearPrefix+y, detailText: "")
            /*
            item.handler = { [unowned self] (item, completion: () -> Void) in
                
                //self.interfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true)
                // This is where we refer to the Years template and push that
                //self.interfaceController?.pushTemplate(downloadsTemplate, animated: true)
                completion()
            }
            */
            items.append(item)
        }
        let section = CPListSection(items: items)
        let yearsTemplate = CPListTemplate(title: "Years", sections: [section])
        
        return yearsTemplate
    }
    
    func templateWillAppear(_ aTemplate: CPTemplate, animated: Bool) {
    }

    func templateDidAppear(_ aTemplate: CPTemplate, animated: Bool) {
    }

    func templateWillDisappear(_ aTemplate: CPTemplate, animated: Bool) {
    }

    func templateDidDisappear(_ aTemplate: CPTemplate, animated: Bool) {
    }

}

/*
@available(iOS 14.0, *)
extension CarPlayTemplateManager: CPInterfaceControllerDelegate {
    func templateWillAppear(_ aTemplate: CPTemplate, animated: Bool) {
    }

    func templateDidAppear(_ aTemplate: CPTemplate, animated: Bool) {
    }

    func templateWillDisappear(_ aTemplate: CPTemplate, animated: Bool) {
    }

    func templateDidDisappear(_ aTemplate: CPTemplate, animated: Bool) {
    }
}
*/

@available(iOS 14.0, *)
extension CarPlayTemplateManager: CPSessionConfigurationDelegate {
    func sessionConfiguration(_ sessionConfiguration: CPSessionConfiguration,
                              limitedUserInterfacesChanged limitedUserInterfaces: CPLimitableUserInterface) {
    }
}
