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
import MediaPlayer

//, MPPlayableContentDataSource, MPPlayableContentDelegate,
// MPPlayableContentManager, MPPlayableContentManagerContext

@available(iOS 14.0, *)
class CarPlayDownloadsTemplate: NSObject, MPPlayableContentDelegate, MPPlayableContentDataSource {

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
    let commandCenter = MPRemoteCommandCenter.shared()
    var nowPlayingSongManager: MPNowPlayingInfoCenter?
    var playableContentManager: MPPlayableContentManager?
    fileprivate(set) var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    init(interfaceController: CPInterfaceController?) {
        self.interfaceController = interfaceController
        super.init()
        self.db = Firestore.firestore()
        self.network = NetworkUtility(db: db)
//        simpleList()
        self.getDownloadedShows()
        playableContentManager = MPPlayableContentManager.shared()
        playableContentManager?.dataSource = self
        playableContentManager?.delegate = self
    }
    
    func numberOfChildItems(at indexPath: IndexPath) -> Int {
        return 0
    }
    
    func contentItem(at indexPath: IndexPath) -> MPContentItem? {
        let item = MPContentItem()
        item.title = shows?[indexPath.row].metadata?.title
        return item
    }
    

//    func numberOfChildItems(at indexPath: IndexPath) -> Int {
//        return 0
//    }
    
  //  func contentItem(at indexPath: IndexPath) -> MPContentItem? {
  //      <#code#>
  //  }
    
    /*
    func simpleList() {
        let item = CPListItem(text: "My title", detailText: "My subtitle")
        item.handler = {
            (item, completion: () -> Void) in
                    completion()
                }
        //item.listItemHandler = { item, completion, [weak self] in
         // Start playback asynchronously…
        // self.interfaceController.pushTemplate(CPNowPlayingTemplate.shared(), animated: true)
        // completion()
        //}
        let section = CPListSection(items: [item])
        let listTemplate = CPListTemplate(title: "Albums", sections: [section])
        self.interfaceController?.setRootTemplate(listTemplate, animated: true)
    }
    */
    
    func getDownloadedShows() {
        network.getAllDownloadDocs() {
            (response: [ShowMetadataModel]?) -> Void in
            DispatchQueue.main.async{
              //  self.playableContentManager?.beginUpdates()
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
             //   self.playableContentManager?.endUpdates()
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
            //let completion = {}
            
            item.handler = {
                (item, completion: () -> Void) in
                print(item.description)
                        completion()
                    }

            //item.handler!(item) {
            //    print("Selected item")
           // }
            
            items.append(item)
            //item.handler = {
                
            //(CPSelectableListItem, @escaping () -> Void) -> Void
           // }
            //listItemHandler = { item, completion, [weak self] in
             // Start playback asynchronously…
             //self.interfaceController.pushTemplate(CPNowPlayingTemplate.shared(), animated: true)
            // completion()
            //}
        }
        
                
        let section = CPListSection(items: items)
        let listTemplate = CPListTemplate(title: "Downloaded Shows", sections: [section])
        self.interfaceController?.setRootTemplate(listTemplate, animated: true)
    }

    
    func playableContentManager(_ contentManager: MPPlayableContentManager, initiatePlaybackOfContentItemAt indexPath: IndexPath, completionHandler: @escaping (Error?) -> Void) {
        print(indexPath)
        completionHandler(nil)
    }

}
