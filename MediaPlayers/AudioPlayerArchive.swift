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
    var showMetadataModel: ShowMetadataModel? {
        didSet {
            // Reset per-show fallback state when the user switches shows.
            let oldId = oldValue?.metadata?.identifier
            let newId = showMetadataModel?.metadata?.identifier
            if oldId != newId {
                pathsToForceStream.removeAll()
            }
        }
    }
    var isStreaming: Bool = false  // Track whether we're streaming or playing local files
    var currentShowType: ShowType = .archive
    /// Cached artwork image for Now Playing info (lock screen, CarPlay, Control Center)
    var currentArtworkImage: UIImage?
    private var currentArtworkURL: URL?
    /// Suppresses playback state saves during advance-to-index loops
    private var isSeeking = false
    /// Counts consecutive AVPlayerItem failures so we can skip a few bad tracks
    /// before giving up entirely. Reset whenever an item successfully becomes ready.
    private var consecutiveFailures = 0
    private static let maxConsecutiveFailures = 3
    /// Local file paths that have failed in-session and should be skipped in favor
    /// of the streaming URL. Persists across queue rebuilds within the same show;
    /// cleared when `showMetadataModel` switches to a different show.
    private var pathsToForceStream = Set<String>()
    private let notificationCenter: NotificationCenter
    private var playCommandTarget: Any?
    private var pauseCommandTarget: Any?
    private var nextTrackCommandTarget: Any?
    private var shouldResumeAfterInterruption = false
    private var state = State.idle {
        didSet { stateDidChange() }
    }
    
    private init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        super.init()
        self.setupCommandCenter()
        self.setupInterruptionHandling()
    }

    static func normalizedStartIndex(_ index: Int, count: Int) -> Int? {
        guard count > 0 else { return nil }
        return min(max(index, 0), count - 1)
    }

    private func setupInterruptionHandling() {
        notificationCenter.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            shouldResumeAfterInterruption = (state == .playing || state == .rewind)
            if shouldResumeAfterInterruption {
                state = .paused
            }
        case .ended:
            guard let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if shouldResumeAfterInterruption, options.contains(.shouldResume) {
                // Reactivate the session and resume playback.
                try? AVAudioSession.sharedInstance().setActive(true)
                self.play()
            }
            shouldResumeAfterInterruption = false
        @unknown default:
            break
        }
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
        let targetIndex = max(index - 1, 0)
        self.pause()

        guard let tracks = self.showMetadataModel?.mp3Array, !tracks.isEmpty else { return }

        if currentShowType == .phishIn {
            let urls = tracks.compactMap { $0.name.flatMap { URL(string: $0) } }
            if !urls.isEmpty {
                loadStreamingFromURLs(urls, startingAt: targetIndex)
            }
        } else if isStreaming {
            loadStreamingQueuePlayer(startingAt: targetIndex)
        } else {
            loadQueuePlayer(tracks: tracks, startingAt: targetIndex)
        }

        self.state = .rewind
        self.play()
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
        consecutiveFailures = 0
        // Note: pathsToForceStream is NOT cleared here — it must survive queue
        // rebuilds within the same show so the failed local file stays skipped.
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
    
    /// Silently re-downloads a track whose local file failed playback. The
    /// download manager will overwrite the bad file on success and validate the
    /// new copy. On success we drop the path from `pathsToForceStream` so the
    /// rest of the current session also benefits from the fresh file.
    private func triggerAutoRedownload(forFailedURL failedURL: URL, trackIndex: Int) {
        guard let identifier = showMetadataModel?.metadata?.identifier else { return }
        let tracks = showMetadataModel?.mp3Array
        let trackName = (tracks != nil && trackIndex < tracks!.count ? tracks![trackIndex].name : nil) ?? failedURL.lastPathComponent
        guard let downloadURL = utils.trackStreamingURLfromNameAndIdentifier(identifier: identifier, name: trackName) else { return }

        print("AudioPlayerArchive: auto-redownloading bad local file \(trackName)")
        BackgroundDownloadManager.shared.download(from: downloadURL) { [weak self] localURL, error in
            if let error = error {
                print("AudioPlayerArchive: auto-redownload failed for \(trackName): \(error.localizedDescription)")
                return
            }
            print("AudioPlayerArchive: auto-redownload succeeded for \(trackName) → \(localURL?.path ?? "?")")
            DispatchQueue.main.async {
                self?.pathsToForceStream.remove(failedURL.path)
            }
        }
    }

    /// Marks a failed local file path as "force stream" and rebuilds the queue from
    /// the current track. The next pass through `resolveTrackURL` will pick the
    /// streaming URL for the bad track and keep local URLs for everything else.
    /// Returns true if a rebuild was scheduled. Used to recover from corrupt or
    /// truncated downloaded files without surgically mutating the live queue
    /// around a failed item (which AVQueuePlayer doesn't reliably recover from).
    private func attemptStreamingFallback(forFailedURL failedURL: URL) -> Bool {
        guard failedURL.isFileURL,
              !pathsToForceStream.contains(failedURL.path),
              showMetadataModel?.metadata?.identifier != nil,
              let tracks = showMetadataModel?.mp3Array,
              !tracks.isEmpty else {
            return false
        }

        pathsToForceStream.insert(failedURL.path)
        let currentIndex = getCurrentTrackIndex()
        print("AudioPlayerArchive: local file failed, rebuilding queue with streaming fallback for \(failedURL.lastPathComponent), starting at track \(currentIndex)")

        // Kick off a silent re-download of the bad file so future sessions have
        // a good copy. The user gets streaming playback now; the disk gets
        // repaired in the background.
        triggerAutoRedownload(forFailedURL: failedURL, trackIndex: currentIndex)

        // Defer so we're not rebuilding the queue from inside the failed item's KVO callback.
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let tracks = self.showMetadataModel?.mp3Array else { return }
            self.loadQueuePlayer(tracks: tracks, startingAt: currentIndex)
            self.play()
        }
        return true
    }

    /// Returns the best URL to play a track: a local file if one exists on disk
    /// and hasn't been marked bad this session, otherwise an archive.org streaming
    /// URL. Ensures downloaded tracks play offline by default, and that a known-bad
    /// downloaded file falls back to streaming for the rest of the show.
    private func resolveTrackURL(for track: ShowMP3, identifier: String?) -> URL? {
        guard let name = track.name else { return nil }
        if let localURL = utils.trackURLfromName(name: name),
           !pathsToForceStream.contains(localURL.path),
           FileManager.default.fileExists(atPath: localURL.path) {
            return localURL
        }
        guard let id = identifier else { return nil }
        return utils.trackStreamingURLfromNameAndIdentifier(identifier: id, name: name)
    }

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
        let identifier = showMetadataModel?.metadata?.identifier
        guard let startIndex = Self.normalizedStartIndex(index, count: tracks.count) else { return }
        for track in tracks[startIndex...] {
            if let url = resolveTrackURL(for: track, identifier: identifier) {
                prepareToPlay(url: url)
            }
        }
        guard !playerItems.isEmpty else { return }
        playerQueue = AVQueuePlayer(items: playerItems)
    }

    func loadStreamingQueuePlayer(startingAt index: Int = 0) {
        print("\(timestamp()) streaming, starting at index \(index)")
        cleanQueue()
        isStreaming = true  // Set flag for streaming playback
        guard let tracks = self.showMetadataModel?.mp3Array, let id = self.showMetadataModel?.metadata?.identifier else { return }
        guard let startIndex = Self.normalizedStartIndex(index, count: tracks.count) else { return }
        for track in tracks[startIndex...] {
            if let url = resolveTrackURL(for: track, identifier: id) {
                prepareToPlay(url: url)
            }
        }
        guard !playerItems.isEmpty else { return }
        playerQueue = AVQueuePlayer(items: playerItems)
    }

    /// Load streaming queue from direct MP3 URLs (e.g., Phish.in tracks).
    func loadStreamingFromURLs(_ urls: [URL], startingAt index: Int = 0) {
        print("\(timestamp()) streaming from direct URLs, starting at index \(index)")
        cleanQueue()
        isStreaming = true
        guard let startIndex = Self.normalizedStartIndex(index, count: urls.count) else { return }
        for url in urls[startIndex...] {
            prepareToPlay(url: url)
        }
        guard !playerItems.isEmpty else { return }
        playerQueue = AVQueuePlayer(items: playerItems)
    }

    func reLoadQueuePlayer(tracks: [ShowMP3]) {
        //cleanQueue()
        guard let pq = playerQueue else { return }
        pq.removeAllItems()
        let identifier = showMetadataModel?.metadata?.identifier
        for track in tracks {
            if let url = resolveTrackURL(for: track, identifier: identifier) {
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
            if let url = resolveTrackURL(for: track, identifier: id) {
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
                    self?.updateNowPlayingInfo()
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
        // Skip saves while advancing through the queue to reach a target index
        guard !isSeeking else { return }

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
            savedAt: Date(),
            showTypeRaw: currentShowType == .phishIn ? "phishIn" : currentShowType == .downloaded ? "downloaded" : "archive"
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
        self.currentShowType = state.showType
        
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
        if state.showType == .phishIn {
            // Phish.in tracks store direct MP3 URLs in the name field
            let urls = tracks.compactMap { $0.name.flatMap { URL(string: $0) } }
            if !urls.isEmpty {
                loadStreamingFromURLs(urls, startingAt: state.trackIndex)
            } else {
                completion(false)
                return
            }
        } else if isStreaming {
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
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        case .playing:
            notificationCenter.post(name: .playbackStarted, object: self.playerQueue)
            updateNowPlayingInfo(rate: 1.0)
        case .paused:
            notificationCenter.post(name: .playbackPaused, object: self.playerQueue)
            updateNowPlayingInfo(rate: 0.0)
        case .rewind:
            notificationCenter.post(name: .playbackRewind, object: self.playerQueue)
            updateNowPlayingInfo(rate: 1.0)
        }
    }
}

// MARK: - Now Playing Info
extension AudioPlayerArchive {
    /// Updates the system Now Playing info center (lock screen, Control Center, CarPlay).
    func updateNowPlayingInfo(rate: Float? = nil) {
        guard let currentItem = playerQueue?.currentItem,
              let mp3s = showMetadataModel?.mp3Array,
              let md = showMetadataModel?.metadata else {
            return
        }

        let currentIndex = getCurrentTrackIndex()
        guard currentIndex < mp3s.count else { return }

        var info = [String: Any]()

        // Track info
        info[MPMediaItemPropertyTitle] = mp3s[currentIndex].title ?? mp3s[currentIndex].name
        if let date = md.date, let coverage = md.coverage {
            info[MPMediaItemPropertyAlbumTitle] = "\(date), \(coverage)"
        } else {
            info[MPMediaItemPropertyAlbumTitle] = md.date ?? md.venue ?? ""
        }
        info[MPMediaItemPropertyArtist] = md.creator ?? md.collection?.first

        // Playback position
        let duration = CMTimeGetSeconds(currentItem.duration)
        if duration.isFinite && duration > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = playerQueue?.currentTime().seconds ?? 0
        info[MPNowPlayingInfoPropertyPlaybackRate] = rate ?? (playerQueue?.rate ?? 0.0)

        // Artwork — use cached cover art if available, otherwise fall back to app icon
        let artworkImage = currentArtworkImage ?? UIImage(named: "Chateau80")
        if let image = artworkImage {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    /// Set the cover art URL for the current show. Downloads the image asynchronously
    /// and updates Now Playing info once loaded.
    func setArtworkURL(_ url: URL?) {
        guard url != currentArtworkURL else { return }
        currentArtworkURL = url
        currentArtworkImage = nil

        guard let url = url else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self, let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                // Only apply if the URL hasn't changed while we were downloading
                guard self.currentArtworkURL == url else { return }
                self.currentArtworkImage = image
                self.updateNowPlayingInfo()
            }
        }.resume()
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
                // Persist playback state on every track change
                savePlaybackState()
            }
        } else if context == &playerItemKVOContext {
            if keyPath == #keyPath(AVPlayerItem.status) {
                guard let playerItem = object as? AVPlayerItem else { return }
                let status = playerItem.status
                switch status {
                case .readyToPlay:
                    consecutiveFailures = 0
                    if self.playerQueue?.rate ?? 0.0 > 0.0 || self.state == .playing {
                        self.state = .playing
                    }
                case .failed:
                    var failedURL: URL?
                    if let item = self.playerQueue?.currentItem, let error = item.error {
                        var userInfo: [String: Any] = ["error": error]
                        failedURL = (item.asset as? AVURLAsset)?.url
                        if let url = failedURL { userInfo["failedURL"] = url }
                        let nsErr = error as NSError
                        print("AudioPlayerArchive: item failed — domain=\(nsErr.domain) code=\(nsErr.code) url=\(failedURL?.absoluteString ?? "nil") underlying=\(nsErr.userInfo[NSUnderlyingErrorKey] ?? "nil")")
                        notificationCenter.post(name: .playbackFailed, object: self.playerQueue, userInfo: userInfo)
                    }

                    // If a downloaded local file failed (corrupt/truncated), try the
                    // streaming version of the same track before skipping.
                    if let url = failedURL, attemptStreamingFallback(forFailedURL: url) {
                        break
                    }

                    let wasActive = (self.state == .playing || self.state == .rewind)
                    let hasMoreItems = (self.playerQueue?.items().count ?? 0) > 1
                    if wasActive && hasMoreItems && consecutiveFailures < AudioPlayerArchive.maxConsecutiveFailures {
                        consecutiveFailures += 1
                        print("AudioPlayerArchive: item failed, skipping to next track (attempt \(consecutiveFailures)/\(AudioPlayerArchive.maxConsecutiveFailures))")
                        self.playerQueue?.advanceToNextItem()
                        self.playerQueue?.play()
                    } else {
                        consecutiveFailures = 0
                        self.state = .idle
                    }
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
