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
class CarPlayDownloadsTemplate: NSObject, CPInterfaceControllerDelegate {

    let fileManager = FileManager.default
    let notificationCenter: NotificationCenter = .default
    let interfaceController: CPInterfaceController
    let commandCenter = MPRemoteCommandCenter.shared()
    var shows: [ShowMetadataModel]?
    var selectedShow: ShowMetadataModel?
    let network = NetworkUtility()
    let utils = Utils()
    let archiveAPI = ArchiveAPI()
    let player = AudioPlayerArchive.shared
    var isPlaying = false
    
    // Keep a strong reference to self while active
    private var selfRetainer: CarPlayDownloadsTemplate?
    
    private var playCommandTarget: Any?
    private var pauseCommandTarget: Any?
    private var togglePlayPauseCommandTarget: Any?
    private var nextTrackCommandTarget: Any?
    private var previousTrackCommandTarget: Any?
    
    private var timerToken: Any?
    private weak var timerTokenPlayer: AVQueuePlayer?
    
    init(interfaceController: CPInterfaceController, decade: String?, year: String?, selectedShow: ShowMetadataModel? = nil) {
        self.interfaceController = interfaceController
        super.init()
        self.selfRetainer = self // Retain self while active
        self.interfaceController.delegate = self
        
        // If a show is pre-selected, play it directly
        if let show = selectedShow {
            self.selectedShow = show
            self.playShow()
        } else {
            // Otherwise, load shows by decade/year as before
            self.getDownloadedShows(decade: decade, year: year)
        }
        
        notificationCenter.addObserver(self, selector: #selector(playbackDidStart), name: .playbackStarted, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackDidPause), name: .playbackPaused, object: self.player.playerQueue)
        notificationCenter.addObserver(self, selector: #selector(playerQueueItemStatusChanged(_:)), name: .playerQueueItemStatusChanged, object: nil)
        // Setup remote command handlers
        setupRemoteCommandHandlers()
    }
    
    deinit {
        notificationCenter.removeObserver(self)
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
            if let trackURL = utils.trackURLfromName(name: song.name) {
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
        Task {
            try? await self.interfaceController.pushTemplate(listTemplate, animated: true)
        }
    }
    
    func playShow() {
        guard let show = selectedShow else {
            print("No show selected")
            return
        }
        // Tapping the show that's already loaded resumes where it left off
        // instead of restarting from track one.
        if player.showMetadataModel?.metadata?.identifier == show.metadata?.identifier,
           player.playerQueue != nil {
            player.play()
            interfaceController.pushNowPlaying()
            return
        }
        player.pause(persist: false)
        player.showMetadataModel = show
        // Sync state to PlayerViewModel so phone UI is in sync
        DispatchQueue.main.async {
            PlayerViewModel.shared.currentShow = show
            PlayerViewModel.shared.currentShowType = .downloaded
            PlayerViewModel.shared.isStreaming = false
        }
        // Verify the show has tracks before proceeding
        guard let mp3s = show.mp3Array, !mp3s.isEmpty else {
            print("Show has no tracks")
            return
        }
        // Verify at least one track is accessible
        var hasAccessibleTrack = false
        for song in mp3s {
            if let trackURL = utils.trackURLfromName(name: song.name) {
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
        setupRemoteCommandHandlers()
        loadDownloadedShow()
        interfaceController.pushNowPlaying()
        player.play()
    }
    
    func loadDownloadedShow() {
        guard let mp3s = player.showMetadataModel?.mp3Array,
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
            if self.player.playerQueue?.rate == 0.0 {
                self.player.play()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.pauseCommand.isEnabled = true
        pauseCommandTarget = commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.player.playerQueue?.rate ?? 0.0 > 0.0 {
                self.player.pause()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.togglePlayPauseCommand.isEnabled = true
        togglePlayPauseCommandTarget = commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.player.playerQueue?.rate ?? 0.0 > 0.0 {
                self.player.pause()
            } else {
                self.player.play()
            }
            return .success
        }
        
        commandCenter.nextTrackCommand.isEnabled = true
        nextTrackCommandTarget = commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.player.playerQueue?.advanceToNextItem()
            return .success
        }
        
        commandCenter.previousTrackCommand.isEnabled = true
        previousTrackCommandTarget = commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.player.playerQueue?.seek(to: .zero)
            return .success
        }
    }
    
    /// Now Playing is owned by the engine (nil-safe, band-code names, artwork,
    /// finite-duration guards, updated on its own tick) — delegate, don't duplicate.
    private func updateNowPlayingInfo() {
        player.updateNowPlayingInfo()
    }
    
    @objc private func playbackDidStart(_ notification: Notification) {
        player.updateNowPlayingInfo(rate: 1.0)
    }
    
    @objc private func playbackDidPause(_ notification: Notification) {
        player.updateNowPlayingInfo(rate: 0.0)
    }
    
    @objc private func playerQueueItemStatusChanged(_ notification: Notification) {
        guard let status = notification.userInfo?["status"] as? AVPlayerItem.Status else { return }
        switch status {
        case .readyToPlay:
            print("ready to play (CarPlay)")
            updateNowPlayingInfo()
            var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
            info[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        case .failed:
            print("failed (CarPlay)")
        case .unknown:
            print("unknown status (CarPlay)")
        @unknown default:
            print("nope (CarPlay)")
        }
    }
    
    func setupTimer(completion: @escaping (_ seconds: Double?) -> Void) {
        removePeriodicTimeObserver() // Always remove any existing observer first
        let interval = CMTime(value: 1, timescale: 2)
        if let player = self.player.playerQueue {
            let timerObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] (progressTime) in
                if let s = self?.player.playerQueue?.currentTime().seconds {
                    completion(s)
                }
            }
            self.timerToken = timerObserverToken
            self.timerTokenPlayer = player
        }
    }
    
    func removePeriodicTimeObserver() {
        if let token = self.timerToken, let player = self.timerTokenPlayer {
            player.removeTimeObserver(token)
            self.timerToken = nil
            self.timerTokenPlayer = nil
        }
    }
}

@available(iOS 14.0, *)
private extension CarPlayDownloadsTemplate {

}
