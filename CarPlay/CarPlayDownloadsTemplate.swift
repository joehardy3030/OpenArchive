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

//, MPPlayableContentDataSource, MPPlayableContentDelegate,
// MPPlayableContentManager, MPPlayableContentManagerContext

@available(iOS 14.0, *)
class CarPlayDownloadsTemplate: NSObject, MPPlayableContentDelegate, MPPlayableContentDataSource, CPInterfaceControllerDelegate {

    let fileManager = FileManager.default
    let notificationCenter: NotificationCenter = .default
    let interfaceController: CPInterfaceController?
    let commandCenter = MPRemoteCommandCenter.shared()
    var nowPlayingSongManager: MPNowPlayingInfoCenter?
    var playableContentManager: MPPlayableContentManager?
    var nowPlayingInfo = [String : Any]()
    var shows: [ShowMetadataModel]?
    var selectedShow: ShowMetadataModel?
    var network: NetworkUtility!
    let utils = Utils()
    let archiveAPI = ArchiveAPI()
    var prevController: ArchiveSuperViewController?
    var miniPlayer: MiniPlayerViewController?
    var player: AudioPlayerArchive?
    var auth: Auth?
    var db: Firestore!
    var isPlaying = false
    fileprivate(set) var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    init(interfaceController: CPInterfaceController?) {
        self.interfaceController = interfaceController
        super.init()
        self.interfaceController?.delegate = self
        self.db = Firestore.firestore()
        self.player = AudioPlayerArchive.shared
        self.network = NetworkUtility(db: db)
        self.getDownloadedShows()
        //self.nowPlayingSongManager = MPNowPlayingInfoCenter.default()
        playableContentManager = MPPlayableContentManager.shared()
        playableContentManager?.dataSource = self
        playableContentManager?.delegate = self
        notificationCenter.addObserver(self, selector: #selector(playbackDidStart), name: .playbackStarted, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackDidPause), name: .playbackPaused, object: self.player?.playerQueue)
        
        /*
        if (self.authStateListenerHandle == nil) {
            self.authStateListenerHandle = self.auth?.addStateDidChangeListener { (auth, user) in
                guard user != nil else {
                    print("Nil user")
                    return
                }
                return
            }
        }
        */
    }
    
    
    func numberOfChildItems(at indexPath: IndexPath) -> Int {
        return 0
    }
    
    func contentItem(at indexPath: IndexPath) -> MPContentItem? {
        let item = MPContentItem()
        item.title = shows?[indexPath.row].metadata?.title
        return item
    }
    
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
            item.handler = { [unowned self] (item, completion: () -> Void) in
                print(item.description)
                self.selectedShow = s
                self.playShow()
                self.interfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true)
                completion()
            }
            items.append(item)
        }
                
        let section = CPListSection(items: items)
        let listTemplate = CPListTemplate(title: "My Tapes", sections: [section])
        self.interfaceController?.setRootTemplate(listTemplate, animated: true)
    }
    
    func playableContentManager(_ contentManager: MPPlayableContentManager, initiatePlaybackOfContentItemAt indexPath: IndexPath, completionHandler: @escaping (Error?) -> Void) {
        print(indexPath)
        completionHandler(nil)
    }
    
    func playShow() {
        player?.pause()
        player?.showMetadataModel = selectedShow // Change showMetadata to showModel for consistency
        loadDownloadedShow()  // Loads up showModel and puts it in the queue; viewDidLoad is called after segue, so need to do this here
        self.player?.playerQueue?.addObserver(self, forKeyPath: "currentItem.status", options: .new, context: nil)
        player?.play()
        print("player nominally playing")
    }
    
    func loadDownloadedShow() {
        if let mp3s = self.player?.showMetadataModel?.mp3Array {
            player?.loadQueuePlayer(tracks: mp3s)
            print("Got here")
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == #keyPath(AVQueuePlayer.currentItem.status) {
            let status: AVPlayerItem.Status
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }

            // Switch over status value
            switch status {
            case .readyToPlay:
                setupNotificationView()
                print("ready to play")
            case .failed:
                print("failed ")
            case .unknown:
                print("unknown status")
            default:
                print("nope")
            }
            
        }
    }
    
    // Per song
    func setupNotificationView() {
        guard let ci = self.player?.playerQueue?.currentItem,
            let mp3s = player?.showMetadataModel?.mp3Array,
            let md = player?.showMetadataModel?.metadata
            else { return }
        guard let ct = player?.getCurrentTrackIndex()
        else {
            print("No current track index")
            return
        }
        nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = mp3s[ct].title
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = String(md.date! + ", " + md.coverage!)
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Grateful Dead"
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = CMTimeGetSeconds(ci.duration)
        if let seconds = player?.playerQueue?.currentTime().seconds {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = seconds
        }
        
        if let image = UIImage(named: "Chateau80") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] =
                MPMediaItemArtwork(boundsSize: image.size) { size in
                    return image
            }
        }
        else { print("no image")}
        //self.nowPlayingSongManager?.nowPlayingInfo = nowPlayingInfo
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}

@available(iOS 14.0, *)
private extension CarPlayDownloadsTemplate {
    @objc private func playbackDidStart(_ notification: Notification) {
//        playButton.setBackgroundImage(UIImage(systemName: "pause"), for: .normal)
        print("Item playing")
        setupNotificationView()
    }
    
    @objc private func playbackDidPause(_ notification: Notification) {

        print("Item paused")
    }
}

@available(iOS 14.0, *)
private extension CarPlayDownloadsTemplate {

}
