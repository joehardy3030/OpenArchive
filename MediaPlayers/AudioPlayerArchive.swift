//
//  AudioPlayerArchive.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/6/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import AVKit
import MediaPlayer

class AudioPlayerArchive: NSObject {
    static let shared = AudioPlayerArchive()
    //static let playerQueue = AVQueuePlayer()
    var playerQueue: AVQueuePlayer?
    var playerItems = [AVPlayerItem]()
    var nowPlayingInfo = [String : Any]()
    let commandCenter = MPRemoteCommandCenter.shared()
    let utils = Utils()
    var songDetailsModel = SongDetailsModel()
    var timerToken: Any?
    var showMetadataModel: ShowMetadataModel?
    private let notificationCenter: NotificationCenter
    private var playCommandTarget: Any?
    private var pauseCommandTarget: Any?
    private var nextTrackCommandTarget: Any?
    private var state = State.idle {
        didSet { stateDidChange() }
    }
    
    private init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        super.init()
        self.setupCommandCenter()
    }
    
    deinit {
        if let target = playCommandTarget {
            commandCenter.playCommand.removeTarget(target)
        }

        if let target = pauseCommandTarget {
            commandCenter.pauseCommand.removeTarget(target)
        }

        if let target = nextTrackCommandTarget {
            commandCenter.nextTrackCommand.removeTarget(target)
        }
    }

    func setupCommandCenter() {
        // Add a handler for the play command.
        commandCenter.playCommand.isEnabled = true
        playCommandTarget = commandCenter.playCommand.addTarget { [unowned self] event in
            if self.playerQueue?.rate == 0.0 {
                self.play()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.pauseCommand.isEnabled = true
        pauseCommandTarget = commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.playerQueue?.rate ?? 0.0 > 0.0 {
                self.pause()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.nextTrackCommand.isEnabled = true
        nextTrackCommandTarget = commandCenter.nextTrackCommand.addTarget{ [unowned self] event in
            if let pq = self.playerQueue {
                pq.advanceToNextItem()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            self.rewindToPreviousItem()
            return .success
        }
        
    }
    
    
    @objc func play() {
        self.playerQueue?.play()
        state = .playing
    }

    @objc func pause() {
        switch state {
        case .idle, .paused:
            // Don't need to send a signal if it's already paused
            break
        case .playing, .rewind:
            if let pq = self.playerQueue {
                pq.pause()
                state = .paused
            }
            
            
        }
    }
    
    @objc func rewindToPreviousItem() {
        let index = self.getCurrentTrackIndex()
        self.pause()
        if let mp3s = self.showMetadataModel?.mp3Array {
            self.reLoadQueuePlayer(tracks: mp3s)
        }
        print(index)
        if index>0 {
            for _ in 0..<index-1 {
                if let q = self.playerQueue {
                    print("skipped track")
                    q.advanceToNextItem()
                    
                }
            }
        }
        guard let currentItem = self.playerQueue?.currentItem else { return }

        currentItem.seek(to: CMTime.zero, completionHandler: { _ in
            self.state = .rewind
            self.play()
        })
   }
    
    func getCurrentTrackIndex() -> Int {
        guard let ci = self.playerQueue?.currentItem else { return 0 }
        let destinationURL = ci.asset.value(forKey: "URL") as? URL
        let name = trackNameFromURL(url: destinationURL)
        if let mp3s = showMetadataModel?.mp3Array {
            if mp3s.count > 0 {
                for i in 0...(mp3s.count - 1) {
                    if mp3s[i].name == name?.removingPercentEncoding {
                        return i
                        }
                }
            }
        }
        return 0
    }
    
    func getCurrentTrackTotalTimeString() -> String? {
        guard let ci = self.playerQueue?.currentItem else { return "" }
        let duration = ci.duration
        let seconds = CMTimeGetSeconds(duration)
        var timeString: String?
        if seconds > 0 && seconds < 100000000.0 {
             timeString = utils.getTimerString(seconds: seconds)
        }
        return timeString
    }
    
    func cleanQueue() {
        if (playerItems.count) > 0 {
            playerItems = [AVPlayerItem]()
            removePeriodicTimeObserver()
            playerQueue = nil
        }
    }


    func trackURLfromName(name: String?) -> URL? {
        guard let d = utils.getDocumentsDirectory(), let n = name else { return nil }
        let url = d.appendingPathComponent(n)
        return url
    }

    func trackNameFromURL(url: URL?) -> String? {
        guard let d = utils.getDocumentsDirectory(), let u = url else { return nil }
        let stringD = d.absoluteString
        let lengthStringD = stringD.count
        let stringU = u.absoluteString
        let lengthStringU = stringU.count
        let name = String(stringU.suffix(lengthStringU-lengthStringD))
        return name
    }
    
    func prepareToPlay(url: URL) {
        let asset = AVAsset(url: url)
        let assetKeys = ["playable"]
        let item = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: assetKeys)
        playerItems.append(item)
    }

    func prepareToPlaySong(url: URL) {
        let asset = AVAsset(url: url)
        let assetKeys = ["playable"]
        let lastItem = playerItems.last
        let item = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: assetKeys)
        playerItems.append(item)
        playerQueue?.insert(item, after: lastItem)
    }


    func getTrackItemAndPrepareToPlay(track: ShowMP3) {
        guard let n = track.name else { return }
        if let url = trackURLfromName(name: n) {
            prepareToPlaySong(url: url)
        }
    }

    func loadQueuePlayerTrack() {
        playerQueue = AVQueuePlayer(items: playerItems)
        //print(playerQueue)
    }

    func loadQueuePlayer(tracks: [ShowMP3]) {
        cleanQueue()
        for track in tracks {
            guard let n = track.name else { return }
            if let url = trackURLfromName(name: n) {
                prepareToPlay(url: url)
            }
        }
        playerQueue = AVQueuePlayer(items: playerItems)
        //print(playerQueue)
    }

    func reLoadQueuePlayer(tracks: [ShowMP3]) {
        //cleanQueue()
        guard let pq = playerQueue else { return }
        pq.removeAllItems()
        for track in tracks {
            guard let n = track.name else { return }
            if let url = trackURLfromName(name: n) {
                prepareToPlay(url: url)
            }
        }
        for item in playerItems {
            pq.insert(item, after: nil)
        }
    }
    
    /*
    func rewindFunctionality() {
        // This operation should probably belong to the player class
        var index = self.getCurrentTrackIndex()
        if let mp3s = self.showMetadataModel?.mp3Array {
            self.loadQueuePlayer(tracks: mp3s)
         }
        if let mp = self.getMiniPlayerController() {
            mp.setupShow()
        }

        initialDefaults()
        setupShow()
        self.rewindToPreviousItem(index: index)
    }
    */
    


}

extension AudioPlayerArchive {
        
    func setupTimer(completion: @escaping (_ seconds: Double?) -> Void) {
        //removePeriodicTimeObserver()
        let interval = CMTime(value: 1, timescale: 2)
        
        let timerObserverToken = self.playerQueue?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] (progressTime) in
            if let s = self?.playerQueue?.currentTime().seconds {
                completion(s)
            }
        }
        self.timerToken = timerObserverToken
    }
    
    func removePeriodicTimeObserver() {
        // If a time observer exists, remove it
        if let token = self.timerToken {
            self.playerQueue?.removeTimeObserver(token)
        }
    }
    
    func currentItemTotalTime() -> String? {
        if let ci = self.playerQueue?.currentItem {
            let duration = ci.duration
            let seconds = CMTimeGetSeconds(duration)
            if seconds > 0 && seconds < 100000000.0 {
                let secondsText =  String(format: "%02d", Int(seconds) % 60)
                let minutesText = String(format: "%02d", Int(seconds) / 60)
                let totalTimeText = "\(minutesText):\(secondsText)"
                return totalTimeText
            }
        }
        return "00:00"
    }
    
    func timerSliderHandler(timerValue: Float) {
        if let duration = self.playerQueue?.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            let value = Float64(timerValue) * totalSeconds
            let seekTime = CMTime(value: Int64(value), timescale: 1)
            self.playerQueue?.seek(to: seekTime, completionHandler: { (completedSeek) in
            })
        }
    }

}

private extension AudioPlayerArchive {
    enum State {
        case idle
        case playing
        case paused
        case rewind
    }
}

private extension AudioPlayerArchive {
    func stateDidChange() {
        switch state {
        case .idle:
            notificationCenter.post(name: .playbackStopped, object: nil)
        case .playing:
            notificationCenter.post(name: .playbackStarted, object: self.playerQueue)
        case .paused:
            notificationCenter.post(name: .playbackPaused, object: self.playerQueue)
        case .rewind:
            notificationCenter.post(name: .playbackRewind, object: self.playerQueue)
        }
    }
}

extension Notification.Name {
    static var playbackStarted: Notification.Name {
        return .init(rawValue: "AudioPlayer.playbackStarted")
    }

    static var playbackPaused: Notification.Name {
        return .init(rawValue: "AudioPlayer.playbackPaused")
    }

    static var playbackStopped: Notification.Name {
        return .init(rawValue: "AudioPlayer.playbackStopped")
    }
    
    static var playbackRewind: Notification.Name {
        return .init(rawValue: "AudioPlayer.playbackRewind")
    }

}

extension AudioPlayerArchive {

}
