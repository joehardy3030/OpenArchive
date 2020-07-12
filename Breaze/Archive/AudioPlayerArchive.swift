//
//  AudioPlayerArchive.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/6/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import AVKit

class AudioPlayerArchive: NSObject {
    var playerQueue: AVQueuePlayer!
    var playerItems = [AVPlayerItem]()
    var mp3Array = [ShowMP3]()
    let requiredAssetKeys = [
        "playable",
        "hasProtectedContent"
    ]
    
    override init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch {
            print("nope")
        }
        super.init()
    }

    func play() {
        self.playerQueue?.play()
    }

    func pause() {
        self.playerQueue?.pause()
    }

    func prepareToPlay(url: URL) {
        let asset = AVAsset(url: url)
        let assetKeys = ["playable"]
        let item = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: assetKeys)
        playerItems.append(item)
    }
    
    func loadQueuePlayer(tracks: [ShowMP3]) {
        for track in tracks {
            guard let d = track.destination else { return }
            prepareToPlay(url: d)
        }
        playerQueue = AVQueuePlayer(items: playerItems)
    }
    
    /*
    func playAudioFileController(url: URL)
    {
        self.avPlayer = AVPlayer(url: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = self.avPlayer
    }
    */
    
}
