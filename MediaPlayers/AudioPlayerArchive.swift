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
    var playerQueue: AVQueuePlayer?
    var playerItems = [AVPlayerItem]()
    var nowPlayingInfo = [String : Any]()
    let commandCenter = MPRemoteCommandCenter.shared()
    let utils = Utils()
    var songDetailsModel = SongDetailsModel()
    var timer: ArchiveTimer?
    var showModel: ShowMetadataModel?
    private let notificationCenter: NotificationCenter
    private var state = State.idle {
        // We add a property observer on 'state', which lets us
        // run a function on each value change.
        // didSet { stateDidChange() }
        didSet { stateDidChange() }
    }
    
    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        super.init()
        self.setupCommandCenter()
        
        //notificationCenter.addObserver(self, selector: #selector(HearThisPlayer.playerDidFinishPlaying(note:)),name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
    }

    func setupCommandCenter() {
        // Add a handler for the play command.
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [unowned self] event in
            if self.playerQueue?.rate == 0.0 {
                self.play()
                //self.playerQueue?.play()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.playerQueue?.rate ?? 0.0 > 0.0 {
                self.pause()
                //self.playerQueue?.pause()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget{ [unowned self] event in
            if let pq = self.playerQueue {
                pq.advanceToNextItem()
                return .success
            }
            return .commandFailed
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
        case .playing:
            self.playerQueue?.pause()
            state = .paused
        }
    }

    func getCurrentTrackIndex() -> Int {
        guard let ci = self.playerQueue?.currentItem else { return 0 }
        let destinationURL = ci.asset.value(forKey: "URL") as? URL
        let name = trackNameFromURL(url: destinationURL)
        if let mp3s = showModel?.mp3Array {
            if mp3s.count > 0 {
                for i in 0...(mp3s.count - 1) {
                    if mp3s[i].name == name {
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
        //item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: .new, context: nil)
        playerItems.append(item)
    }

    func prepareToPlaySong(url: URL) {
        let asset = AVAsset(url: url)
        let assetKeys = ["playable"]
        let lastItem = playerItems.last
        let item = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: assetKeys)
        //item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: .new, context: nil)
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
    }

    func loadQueuePlayer(tracks: [ShowMP3]) {
        for track in tracks {
            guard let n = track.name else { return }
            if let url = trackURLfromName(name: n) {
                prepareToPlay(url: url)
            }
        }
        playerQueue = AVQueuePlayer(items: playerItems)
    }
    
}

private extension AudioPlayerArchive {
    enum State {
        case idle
        case playing
        case paused
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
}
