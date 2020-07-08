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
    var avAudioPlayer: AVAudioPlayer?
    var avPlayer: AVPlayer?
    var rateObserver: NSKeyValueObservation?
    var audioItem: AVPlayerItem!
    var playerQueue: AVQueuePlayer!
    let assetQueue = DispatchQueue(label: "randomQueue", qos: .utility)
    let group = DispatchGroup()
    var urlAsset: AVURLAsset?
    var asset: AVAsset!
    var player: AVPlayer!
    var playerItem: AVPlayerItem!
    var playerItems = [AVPlayerItem]()
    var mp3Array = [ShowMP3]()

    // Key-value observing context
    private var playerItemContext = 0

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

    /*
    var asset: AVURLAsset? {
        didSet {
            guard let newAsset = asset else {
                return
            }
            asynchronouslyLoadURLAsset(newAsset, appendDirectly: false)
        }
    }
    */
    
    func setupRateObserver() {
        self.rateObserver = self.avAudioPlayer?.observe(\.rate, options:  [.new, .old], changeHandler: { (player, change) in
            if player.rate == 1  {
                print("Playing")
            }
            else {
                print("Stop")
             }
        })
        // self.rateObserver?.invalidate()
    }
     // Later You Can Remove Observer

    func pause() {
        self.playerQueue?.pause()
    }

    func play() {
        self.playerQueue?.play()
    }

    func prepareToPlay(url: URL) {
        // Create asset to be played
        let asset = AVAsset(url: url)
        
        let assetKeys = ["playable"]
        // Create a new AVPlayerItem with the asset and an
        // array of asset keys to be automatically loaded
        let item = AVPlayerItem(asset: asset,
                                  automaticallyLoadedAssetKeys: assetKeys)
        
        // Register as an observer of the player item's status property
       /*
        item.addObserver(self,
                               forKeyPath: #keyPath(AVPlayerItem.status),
                               options: [.old, .new],
                               context: &playerItemContext)
        
        */
        print(item)
        playerItems.append(item)

    }
    
    func loadQueuePlayer(tracks: [ShowMP3]) {
        print("Load ")
        
        // images.sorted(by: { $0.fileID > $1.fileID })

        for track in tracks {
            guard let d = track.destination else { return }
            prepareToPlay(url: d)
        }
        playerQueue = AVQueuePlayer(items: playerItems)
        play()
        print(playerQueue.items())
    }
    
    /*
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {

        // Only handle observations for the playerItemContext
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
            return
        }

        if keyPath == #keyPath(AVPlayerItem.status) {
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
            case .failed:
                print("item failed")
            case .unknown:
                print("status unknown")
            @unknown default:
                fatalError()
            }
        }
    }
    */
    
    func playAudioFile(url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            print(url)
            self.avAudioPlayer = try AVAudioPlayer(contentsOf: url)
            self.avAudioPlayer?.play()
        }
        catch {
            print("nope")
        }
    }
    
    func playAudioFileController(url: URL)
    {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            
            self.avPlayer = AVPlayer(url: url)
            //         playAudioFileController(url: url)
            
            let playerViewController = AVPlayerViewController()
            playerViewController.player = self.avPlayer
  
        }
        catch{
            print("nope")
        }
    }
    
}
