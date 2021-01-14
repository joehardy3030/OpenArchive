//
//  CarPlayDownloadsTemplate.swift
//  Breaze
//
//  Created by Joseph Hardy on 1/13/21.
//  Copyright © 2021 Carquinez. All rights reserved.
//

import UIKit
import CarPlay
import Firebase

class CarPlayDownloadsTemplate: NSObject  {
    var shows: [ShowMetadataModel]?
    let fileManager = FileManager.default
    var network: NetworkUtility!
    let utils = Utils()
    let archiveAPI = ArchiveAPI()
    var prevController: ArchiveSuperViewController?
    var miniPlayer: MiniPlayerViewController?
    var player: AudioPlayerArchive?
    var isPlaying = false
    var auth: Auth?
    var db: Firestore!
    let interfaceController: CPInterfaceController?
    fileprivate(set) var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    init(interfaceController: CPInterfaceController?) {
        if db != nil {
            network = NetworkUtility(db: db)
        }
        self.interfaceController = interfaceController
        super.init()
        simpleList()
    }
    
    func simpleList() {
        let item = CPListItem(text: "My title", detailText: "My subtitle")
        //item.listItemHandler = { item, completion, [weak self] in
         // Start playback asynchronously…
        // self.interfaceController.pushTemplate(CPNowPlayingTemplate.shared(), animated: true)
        // completion()
        //}
        let section = CPListSection(items: [item])
        let listTemplate = CPListTemplate(title: "Albums", sections: [section])
        self.interfaceController?.setRootTemplate(listTemplate, animated: true)
    }
}
