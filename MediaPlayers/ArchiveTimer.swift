//
//  ArchiveTimer.swift
//  Breaze
//
//  Created by Joseph Hardy on 8/3/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import MediaPlayer

class ArchiveTimer: NSObject {
    var player = AudioPlayerArchive.shared
    var token: Any?
    
    init(player: AudioPlayerArchive?) {
        if let player = player {
            self.player = player
        }
    }
    
    func setupTimer(completion: @escaping (_ seconds: Double?) -> Void) {
        //removePeriodicTimeObserver()
        let interval = CMTime(value: 1, timescale: 2)
        
        let timerObserverToken = self.player.playerQueue?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] (progressTime) in
            //let seconds = CMTimeGetSeconds(progressTime)
            //completion(seconds)
            if let s = self?.player.playerQueue?.currentTime().seconds {
                completion(s)
                print(s)
            }
        }
        token = timerObserverToken
    }
    
    func removePeriodicTimeObserver() {
        // If a time observer exists, remove it
        if let token = self.token {
            self.player.playerQueue?.removeTimeObserver(token)
        }
    }
    
    func currentItemTotalTime() -> String? {
        if let ci = self.player.playerQueue?.currentItem {
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
        if let duration = self.player.playerQueue?.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            let value = Float64(timerValue) * totalSeconds
            let seekTime = CMTime(value: Int64(value), timescale: 1)
            self.player.playerQueue?.seek(to: seekTime, completionHandler: { (completedSeek) in
            })
        }
    }
    


}
