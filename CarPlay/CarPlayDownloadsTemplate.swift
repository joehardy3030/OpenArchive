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
import MediaPlayer

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
    var isPlaying = false
    
    // Keep a strong reference to self while active
    private var selfRetainer: CarPlayDownloadsTemplate?
    
    private var nowPlayingInfoUpdateTimer: Timer?
    private var playCommandTarget: Any?
    private var pauseCommandTarget: Any?
    private var togglePlayPauseCommandTarget: Any?
    private var nextTrackCommandTarget: Any?
    private var previousTrackCommandTarget: Any?
    
    init(interfaceController: CPInterfaceController?, decade: String?, year: String?) {
        self.interfaceController = interfaceController
        super.init()
        self.selfRetainer = self // Retain self while active
        self.interfaceController?.delegate = self
        self.player = AudioPlayerArchive.shared
        self.network = NetworkUtility()
        self.getDownloadedShows(decade: decade, year: year)
        playableContentManager = MPPlayableContentManager.shared()
        playableContentManager?.dataSource = self
        playableContentManager?.delegate = self
        notificationCenter.addObserver(self, selector: #selector(playbackDidStart), name: .playbackStarted, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackDidPause), name: .playbackPaused, object: self.player?.playerQueue)
        
        // Setup remote command handlers
        setupRemoteCommandHandlers()
    }
    
    deinit {
        // Clean up observers and command handlers
        notificationCenter.removeObserver(self)
        player?.playerQueue?.removeObserver(self, forKeyPath: "currentItem.status")
        playableContentManager?.dataSource = nil
        playableContentManager?.delegate = nil
        nowPlayingInfoUpdateTimer?.invalidate()
        
        // Remove command handlers
        if let target = playCommandTarget {
            commandCenter.playCommand.removeTarget(target)
        }
        if let target = pauseCommandTarget {
            commandCenter.pauseCommand.removeTarget(target)
        }
        if let target = togglePlayPauseCommandTarget {
            commandCenter.togglePlayPauseCommand.removeTarget(target)
        }
        if let target = nextTrackCommandTarget {
            commandCenter.nextTrackCommand.removeTarget(target)
        }
        if let target = previousTrackCommandTarget {
            commandCenter.previousTrackCommand.removeTarget(target)
        }
        
        selfRetainer = nil // Release self reference
    }
        
    func numberOfChildItems(at indexPath: IndexPath) -> Int {
        return 0
    }
    
    func contentItem(at indexPath: IndexPath) -> MPContentItem? {
        let item = MPContentItem()
        item.title = shows?[indexPath.row].metadata?.title
        return item
    }
    
    func getDownloadedShows(decade: String?, year: String?) {
        network.getAllDownloadDocs(decade: decade) {
            (response: [ShowMetadataModel]?) -> Void in
            DispatchQueue.main.async{
                if let r = response {
                    // Filter by year if specified
                    if let year = year {
                        self.shows = r.filter { show in
                            if let dateString = show.metadata?.date {
                                let date = self.utils.getDateFromDateString(datetime: dateString)
                                let calendar = Calendar.current
                                let showYear = calendar.component(.year, from: date ?? Date())
                                return String(showYear) == year
                            }
                            return false
                        }
                    } else {
                    self.shows = r
                    }
                    if let ss = self.shows {
                        for s in ss {
                            if !self.checkTracksAndRemove(show: s) {
                                self.network.removeDownloadDataDoc(docID: s.metadata?.identifier) // use callback
                                print(s)
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
            item.handler = { [weak self] (item, completion: () -> Void) in
                guard let self = self else {
                    completion()
                    return
                }
                print(item.description)
                self.selectedShow = s
                self.playShow()
                completion()
            }
            items.append(item)
        }
                
        let section = CPListSection(items: items)
        let listTemplate = CPListTemplate(title: "My Tapes", sections: [section])
        self.interfaceController?.pushTemplate(listTemplate, animated: true)
    }
    
    func playableContentManager(_ contentManager: MPPlayableContentManager, initiatePlaybackOfContentItemAt indexPath: IndexPath, completionHandler: @escaping (Error?) -> Void) {
        print(indexPath)
        completionHandler(nil)
    }
    
    func playShow() {
        guard let show = selectedShow else {
            print("No show selected")
            return
        }
        
        // Remove any existing observers first
        player?.playerQueue?.removeObserver(self, forKeyPath: "currentItem.status")
        
        player?.pause()
        player?.showMetadataModel = show
        
        // Verify the show has tracks before proceeding
        guard let mp3s = show.mp3Array, !mp3s.isEmpty else {
            print("Show has no tracks")
            return
        }
        
        // Verify at least one track is accessible
        var hasAccessibleTrack = false
        for song in mp3s {
            if let trackURL = player?.trackURLfromName(name: song.name) {
                do {
                    let isReachable = try trackURL.checkResourceIsReachable()
                    if isReachable {
                        hasAccessibleTrack = true
                        break
                    }
                } catch {
                    print("Track not accessible: \(error)")
                }
            }
        }
        
        guard hasAccessibleTrack else {
            print("No accessible tracks found")
            return
        }
        
        // Setup all observers and handlers before loading the show
        player?.playerQueue?.addObserver(self, forKeyPath: "currentItem.status", options: .new, context: nil)
        setupRemoteCommandHandlers()
        startNowPlayingInfoUpdates()
        
        // Now load and play the show
        loadDownloadedShow()
        
        // Push the now playing template before starting playback
        self.interfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true) { [weak self] success, error in
            if success {
                // Only start playback after the template is pushed
                self?.player?.play()
                print("player nominally playing")
            } else if let error = error {
                print("Failed to push now playing template: \(error)")
            }
        }
    }
    
    func loadDownloadedShow() {
        guard let player = player,
              let mp3s = player.showMetadataModel?.mp3Array,
              !mp3s.isEmpty else {
            print("Cannot load show: invalid player or no tracks")
            return
        }
        
        // Clear existing queue
        player.playerQueue?.removeAllItems()
        
        // Load new tracks
        player.loadQueuePlayer(tracks: mp3s)
        print("Loaded \(mp3s.count) tracks into queue")
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
                print("ready to play")
                // Update now playing info when item is ready
                updateNowPlayingInfo()
                // Force an immediate play state update
                var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
                info[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
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
        if let creator = md.creator {
            nowPlayingInfo[MPMediaItemPropertyArtist] = creator
        } else if let collections = md.collection {
            nowPlayingInfo[MPMediaItemPropertyArtist] = collections[0]
        } else {
            nowPlayingInfo[MPMediaItemPropertyArtist] = ""
        }
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
    
    private func setupRemoteCommandHandlers() {
        // First remove any existing handlers
        if let target = playCommandTarget {
            commandCenter.playCommand.removeTarget(target)
        }
        if let target = pauseCommandTarget {
            commandCenter.pauseCommand.removeTarget(target)
        }
        if let target = togglePlayPauseCommandTarget {
            commandCenter.togglePlayPauseCommand.removeTarget(target)
        }
        if let target = nextTrackCommandTarget {
            commandCenter.nextTrackCommand.removeTarget(target)
        }
        if let target = previousTrackCommandTarget {
            commandCenter.previousTrackCommand.removeTarget(target)
        }
        
        // Reset targets to nil
        playCommandTarget = nil
        pauseCommandTarget = nil
        togglePlayPauseCommandTarget = nil
        nextTrackCommandTarget = nil
        previousTrackCommandTarget = nil
        
        // Now set up new handlers
        commandCenter.playCommand.isEnabled = true
        playCommandTarget = commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.player?.playerQueue?.rate == 0.0 {
                self.player?.play()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.pauseCommand.isEnabled = true
        pauseCommandTarget = commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.player?.playerQueue?.rate ?? 0.0 > 0.0 {
                self.player?.pause()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.togglePlayPauseCommand.isEnabled = true
        togglePlayPauseCommandTarget = commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.player?.playerQueue?.rate ?? 0.0 > 0.0 {
                self.player?.pause()
            } else {
                self.player?.play()
            }
            return .success
        }
        
        commandCenter.nextTrackCommand.isEnabled = true
        nextTrackCommandTarget = commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.player?.playerQueue?.advanceToNextItem()
            return .success
        }
        
        commandCenter.previousTrackCommand.isEnabled = true
        previousTrackCommandTarget = commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.player?.playerQueue?.seek(to: .zero)
            return .success
        }
    }
    
    private func startNowPlayingInfoUpdates() {
        // Stop any existing timer
        nowPlayingInfoUpdateTimer?.invalidate()
        
        // Create new timer that updates every second
        nowPlayingInfoUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateNowPlayingInfo()
        }
    }
    
    private func updateNowPlayingInfo() {
        guard let player = player,
              let currentItem = player.playerQueue?.currentItem,
              let mp3s = player.showMetadataModel?.mp3Array,
              let md = player.showMetadataModel?.metadata else {
            return
        }
        
        // Get current index - it's not optional
        let currentIndex = player.getCurrentTrackIndex()
        
        var nowPlayingInfo = [String: Any]()
        
        // Basic track info
        nowPlayingInfo[MPMediaItemPropertyTitle] = mp3s[currentIndex].title
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = String(md.date! + ", " + md.coverage!)
        if let creator = md.creator {
            nowPlayingInfo[MPMediaItemPropertyArtist] = creator
        } else if let collections = md.collection {
            nowPlayingInfo[MPMediaItemPropertyArtist] = collections[0]
        }
        
        // Playback info
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = CMTimeGetSeconds(currentItem.duration)
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.playerQueue?.currentTime().seconds ?? 0
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.playerQueue?.rate ?? 0.0
        
        // Artwork
        if let image = UIImage(named: "Chateau80") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in
                return image
            }
        }
        
        // Update the now playing info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}

@available(iOS 14.0, *)
private extension CarPlayDownloadsTemplate {
    @objc private func playbackDidStart(_ notification: Notification) {
        print("Item playing")
        // Force an immediate play state update
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        // Then update all other info
        updateNowPlayingInfo()
    }
    
    @objc private func playbackDidPause(_ notification: Notification) {
        print("Item paused")
        // Force an immediate pause state update
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        // Then update all other info
        updateNowPlayingInfo()
    }
}

@available(iOS 14.0, *)
private extension CarPlayDownloadsTemplate {

}
