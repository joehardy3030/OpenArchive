//
//
//  AudioPlayer.swift
//
//  Created by MDobekidis
//

import Foundation
import AVFoundation
import UIKit
import Signals
import Alamofire

class AudioPlayer: NSObject {
    
    public var audioPlayerConfig:Dictionary<String,Any> = [
        "loop": false,
        "volume": 1.0
    ]
    
    private var playerViewControllerKVOContext = 0
    
    var audioQueueObserver: NSKeyValueObservation?
    var audioQueueStatusObserver: NSKeyValueObservation?
    var audioQueueBufferEmptyObserver: NSKeyValueObservation?
    var audioQueueBufferAlmostThereObserver: NSKeyValueObservation?
    var audioQueueBufferFullObserver: NSKeyValueObservation?
    var audioQueueStallObserver: NSKeyValueObservation?
    var audioQueueWaitingObserver: NSKeyValueObservation?
    var assetPoolObserver: NSKeyValueObservation?
    
    var playbackLikelyToKeepUpKeyPathObserver: NSKeyValueObservation?
    var playbackBufferEmptyObserver: NSKeyValueObservation?
    var playbackBufferFullObserver: NSKeyValueObservation?
    /////
    var audioItem:AVPlayerItem!
    let onError = Signal<(message:String, error:Error)>()
    let onCollectionReady = Signal<Bool>()
    
    // SAMPLE LIST //
    let trackArr:Array<String> = [
        "https://freemusicarchive.org/file/music/ccCommunity/Rotten_Bliss/The_Nightwatchman_Sings/Rotten_Bliss_-_08_-_Timer_Erase.mp3",
        "https://freemusicarchive.org/file/music/no_curator/Magna_Ingress/Bloody_Shadows/Magna_Ingress_-_03_-_The_Hunt_Timegate_Mix.mp3",
        "https://freemusicarchive.org/file/music/WFMU/Lee_Rosevere/Music_To_Wake_Up_To/Lee_Rosevere_-_02_-_Morning_Mist.mp3"
    ]
    //////////////////
    let assetQueue = DispatchQueue(label: "randomQueue", qos: .utility)
    let group = DispatchGroup()
    
    let assetKeysRequiredToPlay = [
        "playable"
    ]
    
    private let player = AVPlayer()
    private var playerQueue : AVQueuePlayer?
    
    var AVItemPool:Array<AVPlayerItem> = [] {
        didSet {
            print("item was added", self.AVItemPool.count)
            if self.AVItemPool.count == trackArr.count {
                self.onCollectionReady.fire(true)
            }
        }
    }
    
    
    var asset: AVURLAsset? {
        didSet {
            guard let newAsset = asset else { return }
            
            asynchronouslyLoadURLAsset(newAsset, appendDirectly: false)
        }
    }
    
    var dynamicAsset: AVURLAsset? {
        didSet {
            guard let newDAsset = dynamicAsset else { return }
            
            asynchronouslyLoadURLAsset(newDAsset, appendDirectly: true)
        }
    }
    
    public var duration: Double {
        guard let currentItem = player.currentItem else { return 0.0 }
        
        return CMTimeGetSeconds(currentItem.duration)
    }
    
    var rate: Float {
        get {
            return player.rate
        }
        
        set {
            player.rate = newValue
        }
    }
    
    /*
     A formatter for individual date components used to provide an appropriate
     value for the `startTimeLabel` and `durationLabel`.
     */
    let timeRemainingFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        
        return formatter
    }()
    
    /////////////////////  END OF INITIAL VALUES ////////////////////////////
    
    
    /**
     seeks 15 seconds backwards
     */
    public func seek15Backwards() {
        let seconds : Int64 = Int64(15)
        let targetTime:CMTime = CMTimeMake(value: seconds, timescale: 1)
        let newCurrentTime = (self.playerQueue?.currentTime())! - targetTime
        
        self.playerQueue?.seek(to: newCurrentTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero, completionHandler: { result in
            print("finished seeking")
        })
    }
    
    /**
     seeks 15 seconds forward
     */
    public func seek15Forward() {
        let seconds : Int64 = Int64(15)
        let targetTime:CMTime = CMTimeMake(value: seconds, timescale: 1)
        let newCurrentTime = (self.playerQueue?.currentTime())! + targetTime
        
        self.playerQueue?.seek(to: newCurrentTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero, completionHandler: { result in
            print("finished seeking")
        })
    }
    
    /**
     Loads and appends directly a track to the currently playing queue
     */
    public func appendQueueItems(track:String) {
        self.assetQueue.async {
            self.group.wait()
            self.group.enter()
            let fileURL = NSURL(string: track)
            self.dynamicAsset = AVURLAsset(url: fileURL! as URL, options: nil)
        }
    }
    
    /**
     Downloads the currently playing track
     */
    public func downloadCurrentlyPlayingTrack(callback: @escaping (String) -> ()){
        let currentItemUrl = (self.playerQueue?.currentItem?.asset as! AVURLAsset).url
        
        let fileUrl = self.getSaveFileUrl(fileName: currentItemUrl.absoluteString)
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (fileUrl, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        Alamofire.download(currentItemUrl, to:destination)
            .downloadProgress { (progress) in
                print((String)(progress.fractionCompleted*100)+"%")
            }
            .responseData { (data) in
                print("completed")
                print(data.destinationURL!)
                print(data.destinationURL?.absoluteString as Any)
                print(data.destinationURL?.lastPathComponent as Any)
                callback((data.destinationURL?.absoluteString)!)
        }
    }
    
    /**
     Downloads a track from a remote location
     */
    public func download(track: String, callback: @escaping (String)->()) {
        let fileUrl = self.getSaveFileUrl(fileName: track)
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (fileUrl, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        Alamofire.download(track, to:destination)
            .downloadProgress { (progress) in
                print((String)(progress.fractionCompleted*100)+"%")
            }
            .responseData { (data) in
                print("completed")
                print(data.destinationURL!)
                print(data.destinationURL?.absoluteString as Any)
                print(data.destinationURL?.lastPathComponent as Any)
                callback((data.destinationURL?.absoluteString)!)
        }
    }
    
    /**
     Return if player is currently playing a track
     */
    public func isPlaying() -> Bool {
        return (self.playerQueue?.rate)! > Float(0.0)
    }
    
    /**
     Pause playback of audio player
     */
    public func pause() {
        self.playerQueue?.pause()
    }
    
    /**
     Play or Resume playback of current audio player
     */
    public func resume() {
        self.playerQueue?.play()
    }
    
    
    ////////////////////
    
    public func initialize(config:Dictionary<String,Any>?) {
        
        if config != nil {
            self.audioPlayerConfig = config!
        }
        
        ////////////
        
        // load assets as PlayerItems
        self.group.enter()
        var counter = 0;
        for item in self.trackArr {
            print("adding asset: \(item)")
            if counter > 0 {
                self.assetQueue.async {
                    self.group.wait()
                    self.group.enter()
                    let fileURL = NSURL(string: item)
                    self.asset = AVURLAsset(url: fileURL! as URL, options: nil)
                }
            }
            else {
                self.assetQueue.async {
                    let fileURL = NSURL(string: item)
                    self.asset = AVURLAsset(url: fileURL! as URL, options: nil)
                }
            }
            
            counter += 1
        }
        
        ///////////////
        
        self.setupObservers()
        
    }
    
    /**
     Setup observers to monitor playback flow
    */
    private func setupObservers() {
        
        /////////// OBSERVERS /////////////////
        
        self.onCollectionReady.subscribe(with: self) { (isReady) in
            print("Are assets ready: \(isReady)")
            // init player queue
            self.playerQueue = AVQueuePlayer(items: self.AVItemPool)
            self.playerQueue?.usesExternalPlaybackWhileExternalScreenIsActive = true
            
            /////////////
            
            
            //////// MEDIA ////////////
            // listening for current item change
            self.audioQueueObserver = self.playerQueue?.observe(\.currentItem, options: [.new]) { [weak self] (player, _) in
                
                print("media item changed...")
                print("media number ", self?.playerQueue?.items() as Any, self?.playerQueue?.items().count as Any, self?.playerQueue?.currentItem as Any)
                // loop here if needed //
                if self?.audioPlayerConfig["loop"] as! Bool == true && self?.playerQueue?.items().count == 0 && self?.playerQueue?.currentItem == nil {
                    self?.playerQueue?.removeAllItems()
                    self?.playerQueue?.replaceCurrentItem(with: nil)
                    for item:AVPlayerItem in (self?.AVItemPool)! {
                        item.seek(to: CMTime.zero)
                        self?.playerQueue?.insert(item, after: nil)
                    }
                    self?.playerQueue?.play()
                }
            }
            
            // listening for current item status change
            self.audioQueueStatusObserver = self.playerQueue?.currentItem?.observe(\.status, options:  [.new, .old], changeHandler: { (playerItem, change) in
                if playerItem.status == .readyToPlay {
                    print("current item status is ready")
                    print("media Queue ", self.playerQueue?.items() as Any, self.playerQueue?.items().count as Any)
                }
            })
            
            // listening for buffer is empty
            self.audioQueueBufferEmptyObserver = self.playerQueue?.currentItem?.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] (_, _) in
                print("buffering...")
            }
            
            self.audioQueueBufferAlmostThereObserver = self.playerQueue?.currentItem?.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] (_, _) in
                print("buffering ends...")
            }
            
            self.audioQueueBufferFullObserver = self.playerQueue?.currentItem?.observe(\.isPlaybackBufferFull, options: [.new]) { [weak self] (_, _) in
                print("buffering is hidden...")
            }
            
            self.audioQueueStallObserver = self.playerQueue?.observe(\.timeControlStatus, options: [.new, .old], changeHandler: { (playerItem, change) in
                if #available(iOS 10.0, *) {
                    switch (playerItem.timeControlStatus) {
                    case AVPlayerTimeControlStatus.paused:
                        print("Media Paused")
                        
                    case AVPlayerTimeControlStatus.playing:
                        print("Media Playing")
                        
                    case AVPlayerTimeControlStatus.waitingToPlayAtSpecifiedRate:
                        print("Media Waiting to play at specific rate!")
                        
                    default:
                        print("no changes")
                    }
                } else {
                    // Fallback on earlier versions
                }
            })
            
            self.audioQueueWaitingObserver = self.playerQueue?.observe(\.reasonForWaitingToPlay, options: [.new, .old], changeHandler: { (playerItem, change) in
                if #available(iOS 10.0, *) {
                    print("REASON FOR WAITING TO PLAY: ", playerItem.reasonForWaitingToPlay?.rawValue as Any)
                } else {
                    // Fallback on earlier versions
                }
            })
            
            // INITIATE PLAYBACK #PLAY
            self.playerQueue?.play()
        }
    }
    
    
    override init() {
        super.init()
    }
    
    deinit {
        /// Remove any KVO observer.
        self.audioQueueObserver?.invalidate()
        self.audioQueueStatusObserver?.invalidate()
        self.audioQueueBufferEmptyObserver?.invalidate()
        self.audioQueueBufferAlmostThereObserver?.invalidate()
        self.audioQueueBufferFullObserver?.invalidate()
        var audioQueueStallObserver: NSKeyValueObservation?
        var audioQueueWaitingObserver: NSKeyValueObservation?
        self.onCollectionReady.cancelAllSubscriptions()
    }
    
    
    ////////////////////
    /**
     
     */
    func getSaveFileUrl(fileName: String) -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let nameUrl = URL(string: fileName)
        let fileURL = documentsURL.appendingPathComponent((nameUrl?.lastPathComponent)!)
        NSLog(fileURL.absoluteString)
        return fileURL;
    }
    
    func asynchronouslyLoadURLAsset(_ newAsset: AVURLAsset, appendDirectly:Bool = false) {
        /*
         Using AVAsset now runs the risk of blocking the current thread (the
         main UI thread) whilst I/O happens to populate the properties. It's
         prudent to defer our work until the properties we need have been loaded.
         */
        
        newAsset.loadValuesAsynchronously(forKeys: self.assetKeysRequiredToPlay) {
            /*
             The asset invokes its completion handler on an arbitrary queue.
             To avoid multiple threads using our internal state at the same time
             we'll elect to use the main thread at all times, let's dispatch
             our handler to the main queue.
             */
            DispatchQueue.main.async {
                
                /*
                 Test whether the values of each of the keys we need have been
                 successfully loaded.
                 */
                for key in self.assetKeysRequiredToPlay {
                    var error: NSError?
                    
                    if newAsset.statusOfValue(forKey: key, error: &error) == .failed {
                        let stringFormat = NSLocalizedString("error.asset_key_%@_failed.description", comment: "Can't use this AVAsset because one of it's keys failed to load")
                        
                        let message = String.localizedStringWithFormat(stringFormat, key)
                        
                        self.handleErrorWithMessage(message, error: error)
                        
                        return
                    }
                }
                
                // We can't play this asset.
                if !newAsset.isPlayable || newAsset.hasProtectedContent {
                    let message = NSLocalizedString("error.asset_not_playable.description", comment: "Can't use this AVAsset because it isn't playable or has protected content")
                    
                    self.handleErrorWithMessage(message)
                    
                    return
                }
                
                /*
                 We can play this asset. Create a new `AVPlayerItem` and make
                 it our player's current item.
                 */
                if appendDirectly == false {
                    self.AVItemPool.append(AVPlayerItem(asset: newAsset))
                }
                else {
                    print("trying to add: ", newAsset.url)
                    self.AVItemPool.append(AVPlayerItem(asset: newAsset))
                    if self.playerQueue?.canInsert(AVPlayerItem(asset: newAsset), after: self.playerQueue?.items().last) == true {
                        self.playerQueue?.insert(AVPlayerItem(asset: newAsset), after: self.playerQueue?.items().last)
                    }
                    
                }
                self.group.leave()
            }
        }
        
    }
    
    // MARK: - Error Handling
    
    func handleErrorWithMessage(_ message: String?, error: Error? = nil) {
        NSLog("Error occured with message: \(String(describing: message)), error: \(String(describing: error)).")
        
        let alertTitle = NSLocalizedString("alert.error.title", comment: "Alert title for errors")
        let defaultAlertMessage = NSLocalizedString("error.default.description", comment: "Default error message when no NSError provided")
        
        let alert = UIAlertController(title: alertTitle, message: message == nil ? defaultAlertMessage : message, preferredStyle: UIAlertController.Style.alert)
        
        let alertActionTitle = NSLocalizedString("alert.error.actions.OK", comment: "OK on error alert")
        
        let alertAction = UIAlertAction(title: alertActionTitle, style: .default, handler: nil)
        
        alert.addAction(alertAction)
        
        //present(alert, animated: true, completion: nil)
        
        self.onError.fire((message: message!, error: error!))
    }
    
    // MARK: Convenience
    
    func createTimeString(time: Float) -> String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, time))
        
        return timeRemainingFormatter.string(from: components as DateComponents)!
    }
    
}
