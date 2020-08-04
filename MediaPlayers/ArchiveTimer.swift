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
    var player: AudioPlayerArchive?
    
    init(player: AudioPlayerArchive?) {
        self.player = player
    }
    
    func setupTimer(completion: @escaping (_ seconds: String?, _ minutes: String?, _ duration: Double?) -> Void) {

        let interval = CMTime(value: 1, timescale: 2)
        
        player?.playerQueue?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { (progressTime) in
            let seconds = CMTimeGetSeconds(progressTime)
            let secondsString = String(format: "%02d", Int(seconds) % 60)
            let minutesString = String(format: "%02d", Int(seconds) / 60)
          //  print("\(minutesString):\(secondsString)")
           // self.currentItemTotalTime()
            
            if let duration = self.player?.playerQueue?.currentItem?.duration {
                let totalSeconds = CMTimeGetSeconds(duration)
             //   self.timeSlider.value = Float(seconds/totalSeconds)
                completion(secondsString, minutesString, totalSeconds)
            }
        }
        
    }

}
