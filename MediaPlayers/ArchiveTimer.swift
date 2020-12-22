//
//  ArchiveTimer.swift
//  Breaze
//
//  Created by Joseph Hardy on 8/3/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
//import AVKit
import MediaPlayer

class ArchiveTimer: NSObject {
    var player: AudioPlayerArchive?
    
    init(player: AudioPlayerArchive?) {
        self.player = player
    }
    //var queue: AVQueuePlayer?
    
    func setupTimer(completion: @escaping (_ seconds: Double?) -> Void) {

        let interval = CMTime(value: 1, timescale: 2)
        
        self.player?.playerQueue?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { (progressTime) in
            let seconds = CMTimeGetSeconds(progressTime)
            //let secondsString = String(format: "%02d", Int(seconds) % 60)
           // let minutesString = String(format: "%02d", Int(seconds) / 60)
          //  print("\(minutesString):\(secondsString)")
           // self.currentItemTotalTime()
            
             //   self.timeSlider.value = Float(seconds/totalSeconds)
                completion(seconds)
            
        }
        
    }
    
    func currentItemTotalTime() -> String? {
        if let ci = self.player?.playerQueue?.currentItem {
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
        if let duration = self.player?.playerQueue?.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            let value = Float64(timerValue) * totalSeconds
            let seekTime = CMTime(value: Int64(value), timescale: 1)
            self.player?.playerQueue?.seek(to: seekTime, completionHandler: { (completedSeek) in
            })
        }
    }
    


}
