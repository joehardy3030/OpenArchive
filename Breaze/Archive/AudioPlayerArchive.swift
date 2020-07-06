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
    
    func setupRateObserver() {
        self.rateObserver = self.avAudioPlayer?.observe(\.rate, options:  [.new, .old], changeHandler: { (player, change) in
            if player.rate == 1  {
                 print("Playing")
             }else{
                  print("Stop")
             }
        })
        // self.rateObserver?.invalidate()
    }
     // Later You Can Remove Observer

    func pause() {
        self.avAudioPlayer?.pause()
    }

    func resume() {
        self.avAudioPlayer?.play()
    }

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
