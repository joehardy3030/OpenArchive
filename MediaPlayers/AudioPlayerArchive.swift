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
    var playerQueue: AVQueuePlayer?
    var playerItems = [AVPlayerItem]()
    var nowPlayingInfo = [String : Any]()
    let commandCenter = MPRemoteCommandCenter.shared()
    //let notificationCenter = NotificationCenter.default
    let utils = Utils()
    var showModel: ShowMetadataModel?
    
    override init() {
        super.init()
        self.setupCommandCenter()
        //notificationCenter.addObserver(self, selector: #selector(HearThisPlayer.playerDidFinishPlaying(note:)),name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
    }

    func setupCommandCenter() {
        
        // Add a handler for the play command.
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [unowned self] event in
            if self.playerQueue?.rate == 0.0 {
                self.playerQueue?.play()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.playerQueue?.rate ?? 0.0 > 0.0 {
                self.playerQueue?.pause()
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
    }

    @objc func pause() {
        self.playerQueue?.pause()
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

    func getTrackFromName(track: ShowMP3) {
        guard let n = track.name else { return }
        if let url = trackURLfromName(name: n) {
            prepareToPlay(url: url)
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


