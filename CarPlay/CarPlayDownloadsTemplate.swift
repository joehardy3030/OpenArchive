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
        self.db = Firestore.firestore()
        self.network = NetworkUtility(db: db)
        self.interfaceController = interfaceController
        super.init()
//        simpleList()
        self.getDownloadedShows()
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
    
    func getDownloadedShows() {
        network.getAllDownloadDocs() {
            (response: [ShowMetadataModel]?) -> Void in
            DispatchQueue.main.async{
                if let r = response {
                    self.shows = r
                    if let ss = self.shows {
                        for s in ss {
                            if !self.checkTracksAndRemove(show: s) {
                                self.network.removeDownloadDataDoc(docID: s.metadata?.identifier) // use callback
                                print(s)
                                //self.shows?.remove(at: i)
                            }
                        }
                        self.shows = ss.sorted(by: { self.utils.getDateFromDateString(datetime: $0.metadata?.date!)! < self.utils.getDateFromDateString(datetime: $1.metadata?.date!)! })
                    }
                }
                self.createDownloadsCPList()
            }
        }
    }
    
    func checkTracksAndRemove(show: ShowMetadataModel) -> Bool {
        guard let mp3s = show.mp3Array else { return false }
        for song in mp3s {
            if let trackURL = self.player?.trackURLfromName(name: song.name) {
                do {
                    let _ = try trackURL.checkResourceIsReachable()
                    //print(available)
                }
                catch {
                    print(error)
                    return false
                }
            }
        }
        return true
    }
    
    func createDownloadsCPList() {
        var items = [CPListItem]()
        guard let shows = self.shows else { return }
        
        for s in shows {
            let item = CPListItem(text: s.metadata?.date, detailText: s.metadata?.coverage)
            items.append(item)
        }

        let section = CPListSection(items: items)
        let listTemplate = CPListTemplate(title: "Downloaded Shows", sections: [section])
        self.interfaceController?.setRootTemplate(listTemplate, animated: true)
    }


}
