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
    //var mp3Array = [ShowMP3]()
    let requiredAssetKeys = [
        "playable",
        "hasProtectedContent"
    ]
    var nowPlayingInfo = [String : Any]()
    let commandCenter = MPRemoteCommandCenter.shared()
    let utils = Utils()
    var showModel: ShowMetadataModel?
    
    override init() {
        super.init()
        self.setupCommandCenter()
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
    }
    
    func setupNotificationView() {
        nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = "Song"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Live"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Grateful Dead"
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 100.0
        if let seconds = playerQueue?.currentTime().seconds {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = seconds
        }
      //  self.nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size, requestHandler: { (size) -> UIImage in
        //    return img
       // })
        
        if let image = UIImage(named: "cloudy") {
             nowPlayingInfo[MPMediaItemPropertyArtwork] =
                 MPMediaItemArtwork(boundsSize: image.size) { size in
                     return image
             }
         }
        else { print("no image")}
       // print(nowPlayingInfo)

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
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

    func prepareToPlay(url: URL) {
        let asset = AVAsset(url: url)
        let assetKeys = ["playable"]
        let item = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: assetKeys)
        playerItems.append(item)
    }
    
    func loadQueuePlayer(tracks: [ShowMP3]) {
        for track in tracks {
            guard let n = track.name else { return }
            if let url = trackURLfromName(name: n) {
                prepareToPlay(url: url)
            }
        }
        
       // if let p = playerQueue {
        //    p.removeAllItems()
       // }
        playerQueue = AVQueuePlayer(items: playerItems)
    }
}
