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
        if interfaceController == nil {
            print("WARNING: interfaceController is nil!")
        } else {
            print("interfaceController initialized successfully")
        }
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
            item.handler = { [weak self] item, completion in
                if let self = self {
                    print("Selected decade: \(String(describing: item.text))")
                    let yearsTemplate = self.yearsCPListTemplate(decade: item.text)
                    print("Created years template for decade: \(String(describing: item.text))")
                    print("About to push years template")
                    self.interfaceController?.pushTemplate(yearsTemplate, animated: true) { success, error in
                        print("Push template success: \(success)")
                        if let error = error {
                            print("Push template error: \(error)")
                        }
                    }
                }
                completion()
            }
            items.append(item)
        }
                
        let section = CPListSection(items: items)
        let decadesTemplate = CPListTemplate(title: "Decades", sections: [section])
        print("About to set root template")
        self.interfaceController?.setRootTemplate(decadesTemplate, animated: true) { success, error in
            print("Set root template success: \(success)")
            if let error = error {
                print("Set root template error: \(error)")
            }
        }
    }
    
    
    private func yearsCPListTemplate(decade: String?) -> CPListTemplate {
        var items = [CPListItem]()
        var yearPrefix: String
        
        if let t = decade {
            print("Creating years template for decade: \(t)")
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
            let yearText = yearPrefix + y
            let item = CPListItem(text: yearText, detailText: "")
            item.handler = { [weak self] item, completion in
                if let self = self {
                    print("Selected year: \(String(describing: item.text))")
                    // Here we'll create a new template for shows in the selected year
                    _ = CarPlayDownloadsTemplate(interfaceController: self.interfaceController, decade: decade, year: item.text)
                }
                completion()
            }
            items.append(item)
        }
        
        let section = CPListSection(items: items)
        let yearsTemplate = CPListTemplate(title: decade ?? "Years", sections: [section])
        print("Created years template with \(items.count) items")
        
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
