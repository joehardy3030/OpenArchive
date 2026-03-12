//
//  AudioPlayerArchive.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/6/20.
//  Copyright 2020 Carquinez. All rights reserved.
//

import UIKit
import AVKit
import MediaPlayer

class AudioPlayerArchive: NSObject {
    static let shared = AudioPlayerArchive()
    var playerQueue: AVQueuePlayer? {
        willSet {
            // Remove observers from the old queue and its current item
            if let oldQueue = playerQueue {
                oldQueue.removeObserver(self, forKeyPath: #keyPath(AVQueuePlayer.currentItem), context: &playerQueueKVOContext)
                if let oldItem = oldQueue.currentItem {
                    // It's generally safe to attempt removal; KVO doesn't crash if observer isn't present for the given context.
                    oldItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &playerItemKVOContext)
                }
            }
        }
        didSet {
            // Add observers to the new queue and its current item
            if let newQueue = playerQueue {
                // Remove .initial to prevent re-entrant call that causes simultaneous access crash.
                newQueue.addObserver(self, forKeyPath: #keyPath(AVQueuePlayer.currentItem), options: [.old, .new], context: &playerQueueKVOContext)
                if let newItem = newQueue.currentItem {
                    setupStatusObserver(for: newItem)
                }
            }
        }
    }
    private var playerQueueKVOContext = 0
    private var playerItemKVOContext = 1 // New context for item status
    var playerItems = [AVPlayerItem]()
    var nowPlayingInfo = [String : Any]()
    let commandCenter = MPRemoteCommandCenter.shared()
    let utils = Utils()
    var songDetailsModel = SongDetailsModel()
    private var timerToken: Any?
    private weak var timerTokenPlayer: AVQueuePlayer?
    var showMetadataModel: ShowMetadataModel?
    var isStreaming: Bool = false  // Track whether we're streaming or playing local files
    private let notificationCenter: NotificationCenter
    private var playCommandTarget: Any?
    private var pauseCommandTarget: Any?
    private var nextTrackCommandTarget: Any?
    private var state = State.idle {
        didSet { stateDidChange() }
    }
    
    private init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        super.init()
        self.setupCommandCenter()
    }
    
    deinit {
        if let target = playCommandTarget {
            commandCenter.playCommand.removeTarget(target)
        }

        if let target = pauseCommandTarget {
            commandCenter.pauseCommand.removeTarget(target)
        }

        if let target = nextTrackCommandTarget {
            commandCenter.nextTrackCommand.removeTarget(target)
        }

        // Remove KVO observers
        if let queue = playerQueue {
            queue.removeObserver(self, forKeyPath: #keyPath(AVQueuePlayer.currentItem), context: &playerQueueKVOContext)
            if let item = queue.currentItem {
                item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &playerItemKVOContext)
            }
        }
    }

    func setupCommandCenter() {
        // Add a handler for the play command.
        commandCenter.playCommand.isEnabled = true
        playCommandTarget = commandCenter.playCommand.addTarget { [unowned self] event in
            if self.playerQueue?.rate == 0.0 {
                self.play()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.pauseCommand.isEnabled = true
        pauseCommandTarget = commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.playerQueue?.rate ?? 0.0 > 0.0 {
                self.pause()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.nextTrackCommand.isEnabled = true
        nextTrackCommandTarget = commandCenter.nextTrackCommand.addTarget{ [unowned self] event in
            if let pq = self.playerQueue {
                pq.advanceToNextItem()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            self.rewindToPreviousItem()
            return .success
        }
        
    }
    
    
    @objc func play() {
        self.playerQueue?.play()
        print("AudioPlayerArchive: play() called")
        state = .playing
    }

    @objc func pause() {
        switch state {
        case .idle, .paused:
            // Don't need to send a signal if it's already paused
            break
        case .playing, .rewind:
            if let pq = self.playerQueue {
                pq.pause()
                state = .paused
            }
            
            
        }
    }
    
    @objc func rewindToPreviousItem() {
        let index = self.getCurrentTrackIndex()
        self.pause()
        if let mp3s = self.showMetadataModel?.mp3Array {
            if isStreaming {
                self.reLoadStreamingQueuePlayer(tracks: mp3s)
            } else {
                self.reLoadQueuePlayer(tracks: mp3s)
            }
        }
        print(index)
        if index>0 {
            for _ in 0..<index-1 {
                if let q = self.playerQueue {
                    print("skipped track")
                    q.advanceToNextItem()
                    
                }
            }
        }
        guard let currentItem = self.playerQueue?.currentItem else { return }

        currentItem.seek(to: CMTime.zero, completionHandler: { _ in
            self.state = .rewind
            self.play()
        })
   }
    
    func getCurrentTrackIndex() -> Int {
        guard let ci = self.playerQueue?.currentItem else { return 0 }
        let destinationURL = ci.asset.value(forKey: "URL") as? URL
        
        // Extract filename from URL, handling both local and streaming URLs
        var filename: String?
        if let url = destinationURL {
            filename = url.lastPathComponent
        }
        
        if let mp3s = showMetadataModel?.mp3Array {
            if mp3s.count > 0 {
                for i in 0...(mp3s.count - 1) {
                    // Compare against the stored name and its lastPathComponent to support nested paths
                    let storedName = mp3s[i].name
                    let storedFileName = storedName.flatMap { URL(fileURLWithPath: $0).lastPathComponent }
                    if storedName == filename || storedName == filename?.removingPercentEncoding || storedFileName == filename || storedFileName == filename?.removingPercentEncoding {
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
    
    func cleanQueue() {
        if (playerItems.count) > 0 {
            playerItems = [AVPlayerItem]()
            removePeriodicTimeObserver()
            playerQueue = nil
        }
    }


    /*
    func trackURLfromName(name: String?, location: FileLocation) -> URL? {
        guard let n = name else { return nil }
        
        switch location {
        case .local:
            guard let d = utils.getDocumentsDirectory() else { return nil }
            let url = d.appendingPathComponent(n)
            return url
        case .internet:
            return nil
        }
    }
    */
     
     /*
    func trackNameFromURL(url: URL?) -> String? {
        guard let d = utils.getDocumentsDirectory(), let u = url else { return nil }
        let stringD = d.absoluteString
        let lengthStringD = stringD.count
        let stringU = u.absoluteString
        let lengthStringU = stringU.count
        let name = String(stringU.suffix(lengthStringU-lengthStringD))
        return name
    }
    */
    
    func prepareToPlay(url: URL) {
        let asset = AVURLAsset(url: url)
        let assetKeys = ["playable"]
        let item = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: assetKeys)
        playerItems.append(item)
    }

    func prepareToPlaySong(url: URL) {
        let asset = AVURLAsset(url: url)
        let assetKeys = ["playable"]
        let lastItem = playerItems.last
        let item = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: assetKeys)
        playerItems.append(item)
        playerQueue?.insert(item, after: lastItem)
    }


    func getTrackItemAndPrepareToPlay(track: ShowMP3) {
        guard let n = track.name else { return }
        if let url = utils.trackURLfromName(name: n) {
            prepareToPlaySong(url: url)
        }
    }

    func loadQueuePlayerTrack() {
        playerQueue = AVQueuePlayer(items: playerItems)
        //print(playerQueue)
    }

    func loadQueuePlayer(tracks: [ShowMP3], startingAt index: Int = 0) {
        cleanQueue()
        isStreaming = false  // Set flag for local playback
        for track in tracks {
            guard let n = track.name else { return }
            if let url = utils.trackURLfromName(name: n) {
                prepareToPlay(url: url)
            }
        }
        guard !playerItems.isEmpty else { return }
        playerQueue = AVQueuePlayer(items: playerItems)
        
        // Advance to the desired starting index
        if index > 0 && index < playerItems.count {
            print("AudioPlayerArchive: Advancing to index \(index) in loadQueuePlayer")
            for _ in 0..<index {
                playerQueue?.advanceToNextItem() // This should be synchronous enough
            }
        }
        //print(playerQueue)
    }
    
    func loadStreamingQueuePlayer(startingAt index: Int = 0) {
        print("\(timestamp()) streaming, starting at index \(index)")
        cleanQueue()
        isStreaming = true  // Set flag for streaming playback
        guard let tracks = self.showMetadataModel?.mp3Array, let id = self.showMetadataModel?.metadata?.identifier else { return }
        guard !tracks.isEmpty else { return }

        for track in tracks {
            guard let n = track.name else { return }
            
            if let url = utils.trackStreamingURLfromNameAndIdentifier(identifier: id, name: n) {
                prepareToPlay(url: url)
            }
        }
        guard !playerItems.isEmpty else { return }
        playerQueue = AVQueuePlayer(items: playerItems)

        // Advance to the desired starting index
        if index > 0 && index < playerItems.count {
            print("AudioPlayerArchive: Advancing to index \(index) in loadStreamingQueuePlayer")
            for _ in 0..<index {
                playerQueue?.advanceToNextItem() // This should be synchronous enough
            }
        }
        //print(playerQueue)
    }

    func reLoadQueuePlayer(tracks: [ShowMP3]) {
        //cleanQueue()
        guard let pq = playerQueue else { return }
        pq.removeAllItems()
        for track in tracks {
            guard let n = track.name else { return }
            if let url = utils.trackURLfromName(name: n) {
                prepareToPlay(url: url)
            }
        }
        for item in playerItems {
            pq.insert(item, after: nil)
        }
    }
    
    func reLoadStreamingQueuePlayer(tracks: [ShowMP3]) {
        guard let pq = playerQueue, let id = self.showMetadataModel?.metadata?.identifier else { return }
        pq.removeAllItems()
        playerItems = []  // Clear the items array
        
        for track in tracks {
            guard let n = track.name else { return }
            if let url = utils.trackStreamingURLfromNameAndIdentifier(identifier: id, name: n) {
                prepareToPlay(url: url)
            }
        }
        for item in playerItems {
            pq.insert(item, after: nil)
        }
    }
    
    private func setupStatusObserver(for item: AVPlayerItem) {
        item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new], context: &playerItemKVOContext)
        // Manually check initial state since we are not using .initial to avoid re-entrant calls
        if item.status == .readyToPlay && (self.playerQueue?.rate ?? 0.0 > 0.0 || self.state == .playing) {
            self.state = .playing
        }
    }
    
    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
}

extension AudioPlayerArchive {
        
    func setupTimer(completion: @escaping (_ seconds: Double?) -> Void) {
        removePeriodicTimeObserver()
        let interval = CMTime(value: 1, timescale: 2)
        if let player = self.playerQueue {
            let timerObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] (progressTime) in
                if let s = self?.playerQueue?.currentTime().seconds {
                    completion(s)
                }
            }
            self.timerToken = timerObserverToken
            self.timerTokenPlayer = player
        }
    }
    
    func removePeriodicTimeObserver() {
        if let token = self.timerToken, let player = self.timerTokenPlayer {
            player.removeTimeObserver(token)
            self.timerToken = nil
            self.timerTokenPlayer = nil
        }
    }
    
    func currentItemTotalTime() -> String? {
        if let ci = self.playerQueue?.currentItem {
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
        if let duration = self.playerQueue?.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            let value = Float64(timerValue) * totalSeconds
            let seekTime = CMTime(value: Int64(value), timescale: 1)
            self.playerQueue?.seek(to: seekTime, completionHandler: { (completedSeek) in
            })
        }
    }

}

// MARK: - Playback State Persistence
extension AudioPlayerArchive {
    
    /// Save current playback state for later restoration
    func savePlaybackState() {
        guard let model = showMetadataModel,
              model.mp3Array?.isEmpty == false else {
            print("AudioPlayerArchive: No show loaded, skipping state save")
            return
        }
        
        let trackIndex = getCurrentTrackIndex()
        let position = playerQueue?.currentTime().seconds ?? 0.0
        
        // Avoid saving invalid positions
        guard !position.isNaN && !position.isInfinite else {
            print("AudioPlayerArchive: Invalid position, skipping state save")
            return
        }
        
        let state = PlaybackState(
            showMetadataModel: model,
            trackIndex: trackIndex,
            playbackPosition: position,
            isStreaming: isStreaming,
            savedAt: Date()
        )
        
        PlaybackState.save(state)
    }
    
    /// Restore playback state (loads metadata but does NOT start playback)
    /// Returns the restored state if successful, nil otherwise
    func restorePlaybackState() -> PlaybackState? {
        guard let state = PlaybackState.load() else { return nil }
        
        // Restore the show metadata
        self.showMetadataModel = state.showMetadataModel
        self.isStreaming = state.isStreaming
        
        print("AudioPlayerArchive: Restored state - track \(state.trackIndex), position \(state.playbackPosition), streaming: \(state.isStreaming)")
        
        return state
    }
    
    /// Prepare the player queue and seek to position (call after UI is ready)
    func prepareRestoredPlayback(state: PlaybackState, completion: @escaping (Bool) -> Void) {
        guard let tracks = showMetadataModel?.mp3Array, !tracks.isEmpty else {
            completion(false)
            return
        }
        
        // For local playback, verify the first track exists
        if !state.isStreaming {
            if let firstTrackName = tracks.first?.name,
               let localURL = utils.trackURLfromName(name: firstTrackName) {
                if !FileManager.default.fileExists(atPath: localURL.path) {
                    print("AudioPlayerArchive: Local file not found, will stream instead")
                    self.isStreaming = true
                }
            }
        }
        
        // Load the queue
        if isStreaming {
            loadStreamingQueuePlayer(startingAt: state.trackIndex)
        } else {
            loadQueuePlayer(tracks: tracks, startingAt: state.trackIndex)
        }
        
        // Seek to saved position after a short delay to allow player to initialize
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, let queue = self.playerQueue else {
                completion(false)
                return
            }
            
            let seekTime = CMTime(seconds: state.playbackPosition, preferredTimescale: 1000)
            queue.seek(to: seekTime) { finished in
                print("AudioPlayerArchive: Seek to \(state.playbackPosition)s completed: \(finished)")
                completion(finished)
            }
        }
    }
}

private extension AudioPlayerArchive {
    enum State {
        case idle
        case playing
        case paused
        case rewind
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
        case .rewind:
            notificationCenter.post(name: .playbackRewind, object: self.playerQueue)
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
    
    static var playbackRewind: Notification.Name {
        return .init(rawValue: "AudioPlayer.playbackRewind")
    }

    static let playerQueueItemStatusChanged = Notification.Name("AudioPlayerArchive.playerQueueItemStatusChanged")
    static let playbackFailed = Notification.Name("playbackFailed")
}

extension AudioPlayerArchive {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &playerQueueKVOContext {
            if keyPath == #keyPath(AVQueuePlayer.currentItem) {
                if let oldItem = change?[.oldKey] as? AVPlayerItem {
                    oldItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &playerItemKVOContext)
                }
                if let newItem = change?[.newKey] as? AVPlayerItem {
                    // Use helper to add observer and check initial state. Do not use .initial in addObserver.
                    setupStatusObserver(for: newItem)
                }
            }
        } else if context == &playerItemKVOContext {
            if keyPath == #keyPath(AVPlayerItem.status) {
                guard let playerItem = object as? AVPlayerItem else { return }
                let status = playerItem.status
                switch status {
                case .readyToPlay:
                    if self.playerQueue?.rate ?? 0.0 > 0.0 || self.state == .playing {
                        self.state = .playing
                    }
                case .failed:
                    if let item = self.playerQueue?.currentItem, let error = item.error {
                        var userInfo: [String: Any] = ["error": error]
                        if let urlAsset = item.asset as? AVURLAsset {
                            userInfo["failedURL"] = urlAsset.url
                        }
                        notificationCenter.post(name: .playbackFailed, object: self.playerQueue, userInfo: userInfo)
                    }
                    self.state = .idle
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
