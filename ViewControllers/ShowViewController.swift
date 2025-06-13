//
//  ShowViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/4/20.
//  Copyright 2020 Carquinez. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

enum ShowType {
    case archive
    case downloaded
}

enum FileLocation {
    case internet
    case local
}

@available(iOS 13.0, *)
class ShowViewController: ArchiveSuperViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var playButtonLabel: UIButton!
    @IBOutlet weak var showTableView: UITableView!
    @IBOutlet weak var broadcastPlayPauseButton: UIButton!
    let notificationCenter: NotificationCenter = .default
    let fileManager = FileManager.default
    let numRowsBeforeSongs = 4 // date, venue, coverage, transferer
    var showMetadata: ShowMetadata?
    var showMetadataModel: ShowMetadataModel? // Holds all the metadata for a show
    var downloadProgress: [URL: Double] = [:] // To store download progress for tracks
    var showType: ShowType? = .archive
    var fileLocation: FileLocation?
    var isDescriptionExpanded: Bool = false
    var broadcastIsPlaying: Bool = false
    var mp3index: Int = 0
    var isObservingPlayer = false  // Track observer state
    var activityIndicator: UIActivityIndicatorView!
    var pendingDownloadRequests: Set<String> = [] // To track pending download requests
    var pendingStreamTrackName: String? // To track pending stream requests
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.showTableView.delegate = self
        self.showTableView.dataSource = self

        // Setup activity indicator
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = self.view.center // Or self.showTableView.center if preferred
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        // Ensure it's above the table view if table view might obscure it
        // view.bringSubviewToFront(activityIndicator) 

        notificationCenter.addObserver(self, selector: #selector(playbackDidStart), name: .playbackStarted, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackDidPause), name: .playbackPaused, object: self.player.playerQueue)
        notificationCenter.addObserver(self, selector: #selector(playbackDidFail), name: .playbackFailed, object: nil)
        self.navigationItem.title = ""
        switch showType {
        case .archive:
            self.navigationItem.title = utils.getDateFromDateTimeString(datetime: showMetadata?.date)
            print("archive")
            playButtonLabel.setTitle("Stream", for: .normal)
            getIAGetShow()
        case .downloaded:
            self.navigationItem.title = showMetadata?.date
            self.downloadButton.isHidden = true
            playButtonLabel.setTitle("Play", for: .normal)
        default:
            print("No show type")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removePlayerObserver()
    }
    
    deinit {
        notificationCenter.removeObserver(self)
        removePlayerObserver()
    }
    
    @IBAction func downloadShow(_ sender: Any) {
        switch showType {
        case .downloaded:
            print("Do nothing, for now")
        case .archive:
            if playButtonLabel.currentTitle == "Stream" {
                mp3index = 0
                downloadSyncRun()
                playButtonLabel.setTitle("Downloading", for: .normal)
            }
        default:
            print("Do nothing by default")
        }
    }
    
    @IBAction func shareShow(_ sender: Any) {
        let url = utils.urlFromIdentifier(identifier: self.showMetadata?.identifier)
        //let url = utils.urlFromIdentifier(identifier: self.player.showMetadataModel?.metadata?.identifier)
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = sender as? UIView
        present(activityViewController, animated: true, completion: nil)
    }

    @IBAction func playButton(_ sender: Any) {
        if playButtonLabel.currentTitle == "Play" {
            playShow()
        }
        else if playButtonLabel.currentTitle == "Stream" {
            streamShow()
        }
    }

    func streamShow(startingAt index: Int = 0) {
        self.player.pause()
        self.player.showMetadataModel = showMetadataModel // Change showMetadata to showModel for consistency
        self.loadStreamingShow(startingAt: index)  // Loads up showModel and puts it in the queue; viewDidLoad is called after segue, so need to do this here
        self.player.play()
    }

    func playShow(startingAt index: Int = 0) {
        self.player.pause()
        self.player.showMetadataModel = showMetadataModel // Change showMetadata to showModel for consistency
        self.loadDownloadedShow(startingAt: index)  // Loads up showModel and puts it in the queue; viewDidLoad is called after segue, so need to do this here
        self.player.play()
    }

    func loadStreamingShow(startingAt index: Int = 0) {
        // This operation should probably belong to the player class
        if let _ = self.player.showMetadataModel?.mp3Array {
            player.loadStreamingQueuePlayer(startingAt: index)
        }
        if let mp = self.getMiniPlayerController() {
            mp.setupShow()
        }
        setupPlayerObserver()
    }
    
    func loadDownloadedShow(startingAt index: Int = 0) {
        // This operation should probably belong to the player class
        if let mp3s = self.player.showMetadataModel?.mp3Array {
            player.loadQueuePlayer(tracks: mp3s, startingAt: index)
        }
        if let mp = self.getMiniPlayerController() {
            mp.setupShow()
        }
        setupPlayerObserver()
    }
    
    func getIAGetShow() {
        
        guard let id = self.showMetadata?.identifier else { 
            // Optionally, handle the case where identifier is nil early, e.g., show an alert or log.
            // For now, just returning as per original logic if id is nil.
            return 
        }
        let url = archiveAPI.metadataURL(identifier: id)

        // Start activity indicator and hide table view
        activityIndicator.startAnimating()
        showTableView.isHidden = true

        archiveAPI.getIARequestMetadataDecodable(url: url) { (response: ShowMetadataModel?, error: Error?) -> Void in
            DispatchQueue.main.async{
                // Stop activity indicator and show table view
                self.activityIndicator.stopAnimating()
                self.showTableView.isHidden = false

                if let error = error {
                    self.showErrorAlert(title: "Error Fetching Show", message: error.localizedDescription)
                    self.showMetadataModel = nil // Clear data on error
                    self.showTableView.reloadData()
                    return
                }

                guard let showData = response else {
                    self.showErrorAlert(title: "No Data", message: "Show information could not be loaded.")
                    self.showMetadataModel = nil // Clear data
                    self.showTableView.reloadData()
                    return
                }

                self.showMetadataModel = showData
                // Restore avg_rating and num_reviews from the initial shallow showMetadata if available
                // This is because the full metadata API might not always return them or they might differ.
                if let initialShowMeta = self.showMetadata {
                    if let ar = initialShowMeta.avg_rating, let nr = initialShowMeta.num_reviews {
                        self.showMetadataModel?.metadata?.avg_rating = ar
                        self.showMetadataModel?.metadata?.num_reviews = nr
                    }
                }
                
                if let files = self.showMetadataModel?.files {
                    var mp3s = [ShowMP3]()
                    for f in files {
                        if (f.format?.contains("MP3")) ?? false { 
                            let showMP3 = ShowMP3(identifier: self.showMetadata?.identifier, 
                                                  name: f.name, 
                                                  title: f.title, 
                                                  track: f.track)
                            mp3s.append(showMP3)
                        }
                    }
                    self.showMetadataModel?.mp3Array = mp3s.sorted { (item1, item2) -> Bool in // Sort tracks
                        guard let track1 = item1.track, let track2 = item2.track else { return false }
                        return track1.localizedStandardCompare(track2) == .orderedAscending
                    }
                }
                self.showTableView.reloadData()
            }
        }
    }
    
    ///Download manager class
    func downloadShow() {
        guard let mp3s = self.showMetadataModel?.mp3Array else { return }
        for f in mp3s {
            let url = archiveAPI.downloadURL(identifier: self.showMetadata?.identifier, filename: f.name)
            //guard let localURL = self.player.trackURLfromName(name: f.name) else { return }
            guard let localURL = utils.trackURLfromName(name: f.name) else { return }
            if fileManager.fileExists(atPath: localURL.path) {
                DispatchQueue.main.async{
                    self.setDownloadComplete(destination: localURL, name: f.name)
                    self.showTableView.reloadData()
                }
            }
            else {
                archiveAPI.getIADownload(url: url, progressHandler: nil) { 
                    (localFileURL: URL?, error: Error?) -> Void in
                    if let error = error {
                        print("Error downloading \(f.name ?? "unknown file"): \(error.localizedDescription)")
                        // Optionally, update UI to show error for this specific file
                        return
                    }
                    DispatchQueue.main.async{
                        self.setDownloadComplete(destination: localFileURL, name: f.name)
                        self.showTableView.reloadData()
                    }
                }
            }
        }
        print("Download show")
    }
    
    func downloadSyncRun() {
        guard let mp3s = self.showMetadataModel?.mp3Array else { return }
        if mp3index < mp3s.count {
            downloadSync(showMP3: mp3s[mp3index])
            print(mp3index)
        } else {
            print("all done here")
            // Save the download data when all tracks are downloaded
            saveDownloadData()
        }
    }
    
    func downloadSync(showMP3: ShowMP3?) {
        guard let mp3 = showMP3 else { return }
        downloadSong(showMP3: mp3) {
            (destination: URL?) -> Void in
            DispatchQueue.main.async{
                self.setDownloadComplete(destination: destination, name: mp3.name)
                self.showTableView.reloadData()
                self.loadAndPlaySong(showMP3: mp3)
                self.mp3index = self.mp3index + 1
                self.downloadSyncRun()
                //self.playShow()
            }
        }
    }
    
    func loadAndPlaySong(showMP3: ShowMP3?) {
        guard let mp3 = showMP3 else {return }
        if mp3index == 0 {
            player.pause()
            player.cleanQueue()
            player.showMetadataModel = showMetadataModel // Change showMetadata to showModel for consistency
            player.getTrackItemAndPrepareToPlay(track: mp3)
            player.loadQueuePlayerTrack()
            if let mp = self.getMiniPlayerController() {
                mp.setupShow()
            }
        }
        else {
            player.getTrackItemAndPrepareToPlay(track: mp3)
        }
        
    }
    
    ///Download manager class
    func downloadSong(showMP3: ShowMP3?, completion: @escaping (URL?) -> Void) {
        guard let s = showMP3, let trackName = s.name else { 
            completion(nil) // Ensure completion is called even if we bail early
            return 
        }
        let url = archiveAPI.downloadURL(identifier: self.showMetadata?.identifier, filename: trackName)
        guard let localURL = utils.trackURLfromName(name: trackName) else { 
            completion(nil)
            return 
        }

        if fileManager.fileExists(atPath: localURL.path) {
            completion(localURL)
        }
        else {
            // --- Mark as pending and update UI --- START
            self.pendingDownloadRequests.insert(trackName)
            if let mp3s = self.showMetadataModel?.mp3Array {
                if let index = mp3s.firstIndex(where: { $0.name == trackName }) {
                    DispatchQueue.main.async {
                        let indexPath = IndexPath(row: index, section: 2) // Section 2 is tracks
                        if self.showTableView.indexPathsForVisibleRows?.contains(indexPath) ?? false {
                            self.showTableView.reloadRows(at: [indexPath], with: .none)
                        }
                    }
                }
            }
            // --- Mark as pending and update UI --- END
            
            archiveAPI.getIADownload(url: url, progressHandler: { (progress) in
                // --- Clear pending state once progress starts --- START
                if self.pendingDownloadRequests.contains(trackName) {
                    self.pendingDownloadRequests.remove(trackName)
                }
                // --- Clear pending state once progress starts --- END

                self.downloadProgress[localURL] = progress
                
                // Find the index of this track and reload just that row for performance
                if let mp3s = self.showMetadataModel?.mp3Array {
                    if let index = mp3s.firstIndex(where: { $0.name == trackName }) {
                        DispatchQueue.main.async {
                            let indexPath = IndexPath(row: index, section: 2) // Section 2 is tracks
                            if self.showTableView.indexPathsForVisibleRows?.contains(indexPath) ?? false {
                                self.showTableView.reloadRows(at: [indexPath], with: .none)
                            }
                        }
                    }
                }
            }) { 
                (localFileURL: URL?, error: Error?) -> Void in
                // --- Clear pending state on completion --- START
                self.pendingDownloadRequests.remove(trackName)
                // --- Clear pending state on completion --- END

                if let error = error {
                    print("Error downloading \(trackName): \(error.localizedDescription)")
                    // Optionally, update UI to show error for this specific file
                    return
                }
                DispatchQueue.main.async{
                    self.setDownloadComplete(destination: localFileURL, name: trackName)
                    self.showTableView.reloadData()
                }
                completion(localFileURL)
            }
        }
    }
    
    ///Download manager class
    private func setDownloadComplete(destination: URL?, name: String?) {
        var counter = 0
        if let d = destination {
            let count = (self.showMetadataModel?.mp3Array?.count ?? 0)
            for i in 0..<count {
                if self.showMetadataModel?.mp3Array?[i].name == name {
                    self.showMetadataModel?.mp3Array?[i].destination = d
                }
                if self.showMetadataModel?.mp3Array?[i].destination != nil {
                    counter += 1
                }
            }
        }
        print("Set download complete")
    }
    
    private func saveDownloadData() {
        let _ = network.addDownloadDataDoc(showMetadataModel: showMetadataModel)
        print("Save download data")
        playButtonLabel.setTitle("Play", for: .normal)
    }
    
    func selectCurrentTrack() {
        let index = player.getCurrentTrackIndex()
        print("\(timestamp()) select current track \(index)")
        let indexPath = IndexPath(item: index, section: 2)
        self.showTableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableView.ScrollPosition.middle)
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        // The following block for #keyPath(AVQueuePlayer.currentItem.status) is removed.
        // ShowViewController should rely on notifications (.playbackStarted, .playbackPaused, .playbackFailed)
        // to react to player state changes. MiniPlayerViewController is responsible for detailed currentItem.status KVO.
        /*
        if keyPath == #keyPath(AVQueuePlayer.currentItem.status) {
            let status: AVPlayerItem.Status
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            // Switch over status value
            switch status {
            case .readyToPlay:
                selectCurrentTrack()
                print("ready to play show view controller")
            case .failed:
                // This is now handled by the .playbackFailed notification
                break
            case .unknown:
                print("unknown status")
            default:
                print("nope")
            }
        }
        */
        
        // If ShowViewController were observing other keyPaths, their handling would go here.
        // For example:
        // if keyPath == #keyPath(AVQueuePlayer.rate) { ... }

    }

    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: // Info Section
            return 4 // Date, Venue, Coverage, Transferer
        case 1: // Taper's Notes Section
            return isDescriptionExpanded ? 2 : 0 // 2 rows (Source, Description) if expanded, 0 if not
        case 2: // Tracks Section
            return showMetadataModel?.mp3Array?.count ?? 0
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = showTableView.dequeueReusableCell(withIdentifier: "ShowDetailCell", for: indexPath) as! ShowDetailTableViewCell
        
        guard let m = self.showMetadataModel?.metadata else { return UITableViewCell() }
        
        cell.accessoryType = .none
        cell.selectionStyle = .none

        switch indexPath.section {
        case 0: // Info Section
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = m.date
            case 1:
                cell.textLabel?.text = m.venue
            case 2:
                cell.textLabel?.text = m.coverage
            case 3:
                if let sourceArray = m.source, !sourceArray.isEmpty {
                    cell.textLabel?.text = sourceArray.joined(separator: "; ")
                } else {
                    cell.textLabel?.text = "N/A" // Or your preferred placeholder for source
                }
            case 4:
                cell.textLabel?.text = m.transferer
            default:
                break
            }
        case 1: // Taper's Notes Section (only reached if isDescriptionExpanded is true)
            if indexPath.row == 0 { // Source row
                cell.textLabel?.text = m.source?.joined(separator: "; ")
            } else if indexPath.row == 1 { // Description row
                if let description = m.description {
                    let data = description.data(using: .utf8)!
                    do {
                        let attributedString = try NSAttributedString(data: data,
                            options: [.documentType: NSAttributedString.DocumentType.html,
                                    .characterEncoding: String.Encoding.utf8.rawValue],
                            documentAttributes: nil)
                        cell.textLabel?.text = attributedString.string
                    } catch {
                        print("Error parsing HTML: \(error)")
                        cell.textLabel?.text = description
                    }
                } else {
                    cell.textLabel?.text = "No description available."
                }
                cell.textLabel?.applyTextStyle(AppFonts.bodyPrimary)
            }
        case 2: // Tracks Section
            cell.selectionStyle = .default
            if let mp3s = self.showMetadataModel?.mp3Array {
                let track = mp3s[indexPath.row]
                if let title = track.title, let trackNum = track.track {
                    cell.textLabel?.text = trackNum + " " + title
                } else {
                    cell.textLabel?.text = track.name
                }
                cell.textLabel?.applyTextStyle(AppFonts.bodyPrimary)
                
                // Determine download state and configure cell
                if let trackName = track.name {
                    // Check for pending stream first
                    if pendingStreamTrackName == trackName {
                        print("\(self.timestamp()) SVC cellForRowAt: Setting .pendingStream for \(trackName)") // ADDED LOG
                        cell.setDownloadState(.pendingStream)
                    }
                    // Then check download states
                    else if let localURL = utils.trackURLfromName(name: trackName) {
                        // Check if request is pending
                        if self.pendingDownloadRequests.contains(trackName) {
                            cell.setDownloadState(.pendingRequest)
                        }
                        // Check if already downloaded
                        else if track.destination != nil || FileManager.default.fileExists(atPath: localURL.path) {
                            cell.setDownloadState(.downloaded)
                        } 
                        // Check if currently downloading
                        else if let progress = self.downloadProgress[localURL] {
                            cell.setDownloadState(.downloading(progress: Float(progress)))
                        } 
                        // Not downloaded
                        else {
                            cell.setDownloadState(.notDownloaded)
                        }
                    } else {
                        cell.setDownloadState(.notDownloaded)
                    }
                } else {
                    cell.setDownloadState(.notDownloaded)
                }
            }
        default:
            break
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 { // Taper's Notes Header
            let headerView = UIView()
            headerView.backgroundColor = .systemBackground // Set opaque background
            
            let button = UIButton(type: .system)
            button.setTitle(isDescriptionExpanded ? "Hide Notes" : "Notes", for: .normal)
            button.titleLabel?.applyTextStyle(AppFonts.button)
            button.addTarget(self, action: #selector(toggleNotesSection), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview(button)
            
            let topPadding: CGFloat = 0.0

            let separatorView = UIView()
            separatorView.backgroundColor = UIColor.separator
            separatorView.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview(separatorView)

            NSLayoutConstraint.activate([
                // Button constraints
                button.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                button.topAnchor.constraint(equalTo: headerView.topAnchor, constant: topPadding),

                // Separator constraints
                separatorView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
                separatorView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
                separatorView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
                separatorView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale)
            ])
            
            return headerView
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 44
        }
        return 0
    }

    @objc func toggleNotesSection() {
        isDescriptionExpanded.toggle()
        showTableView.reloadSections(IndexSet(integer: 1), with: .automatic)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 2 else { return } // Only handle track selection
        
        let songIndex = indexPath.row
        
        // Check if we're streaming or playing downloaded files
        if playButtonLabel.currentTitle == "Stream" {
            // Set pending state and update UI
            if let trackName = showMetadataModel?.mp3Array?[songIndex].name {
                pendingStreamTrackName = trackName
                print("\(timestamp()) SVC didSelectRow: Cell reload requested for \(trackName)")
                showTableView.reloadRows(at: [indexPath], with: .none)
            }
            // Dispatch the streaming setup to the next run loop cycle
            // to allow the UI to update and show the spinner immediately.
            DispatchQueue.main.async {
                print("\(self.timestamp()) SVC didSelectRow: Dispatch block executing. Starting stream setup.")
                self.streamShow(startingAt: songIndex)
            }
            print("\(timestamp()) SVC didSelectRow: didSelectRowAt finished. UI update is now pending.")
        } else {
            // For downloaded files, check if track exists locally
            if let trackURL = utils.trackURLfromName(name: showMetadataModel?.mp3Array?[songIndex].name) {
                do {
                    let _ = try trackURL.checkResourceIsReachable()
                    print("playShow")
                    playShow(startingAt: songIndex)
                }
                catch {
                    print("Track not available")
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // Only allow selection for track rows
        return indexPath.section == 2 ? indexPath : nil
    }
    
    func showErrorAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}

@available(iOS 13.0, *)
private extension ShowViewController {
    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
    
    @objc private func playbackDidStart(_ notification: Notification) {
        print("\(self.timestamp()) SVC playbackDidStart: Notification received. Current pendingStreamTrackName: \(pendingStreamTrackName ?? "nil")") // ADDED LOG
        if let currentItemAsset = player.playerQueue?.currentItem?.asset as? AVURLAsset {
            print("\(self.timestamp()) SVC playbackDidStart: Current playing item in queue: \(currentItemAsset.url.lastPathComponent)") // ADDED LOG
        }

        // Only clear the pending stream indicator if we're actually playing
        if player.playerQueue?.rate ?? 0.0 > 0.0 {
            if let trackName = pendingStreamTrackName,
               let index = showMetadataModel?.mp3Array?.firstIndex(where: { $0.name == trackName }) {
                pendingStreamTrackName = nil
                let indexPath = IndexPath(row: index, section: 2)
                if showTableView.indexPathsForVisibleRows?.contains(indexPath) ?? false {
                    showTableView.reloadRows(at: [indexPath], with: .none)
                }
            }
        }
        
        // For highlighting the current track:
        selectCurrentTrack() 
        print("ShowViewController: Playback Did Start notification received. Called selectCurrentTrack().") // DIAGNOSTIC
    }

    @objc private func playbackDidPause(_ notification: Notification) {
        print("Item paused")
    }
    
    @objc private func playbackDidFail(_ notification: Notification) {
        // Clear the pending stream indicator on failure.
        if let trackName = pendingStreamTrackName,
           let index = showMetadataModel?.mp3Array?.firstIndex(where: { $0.name == trackName }) {
            pendingStreamTrackName = nil
            let indexPath = IndexPath(row: index, section: 2)
            if showTableView.indexPathsForVisibleRows?.contains(indexPath) ?? false {
                showTableView.reloadRows(at: [indexPath], with: .none)
            }
        }

        if let error = notification.userInfo?["error"] as? Error {
            print("Playback failed with error: \(error.localizedDescription)")
        }
        let isStreaming = notification.userInfo?["isStreaming"] as? Bool ?? false
        let message = isStreaming ? "Could not stream the track. Please check your internet connection and try again." : "Could not play the downloaded track. The file may be corrupt or missing."
        let alert = UIAlertController(title: "Playback Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // Add methods to manage the KVO observer
    func setupPlayerObserver() {
        guard let queue = player.playerQueue else { return }
        if !isObservingPlayer {
            // Do not observe currentItem.status directly in ShowViewController.
            // queue.addObserver(self, forKeyPath: "currentItem.status", options: .new, context: nil)
            
            // If this was the only observation, isObservingPlayer might not need to be set to true.
            // However, if other KVO paths are (or will be) observed by ShowViewController on the player,
            // then isObservingPlayer should be managed accordingly.
            // For now, we comment out the line that would set it true for this specific observation.
            // If no other KVO is intended, 'isObservingPlayer = true' and the print statement could be removed or adjusted.
            // isObservingPlayer = true 
            // print("Added player observer in ShowViewController") // Original print statement
            print("Player observer setup in ShowViewController (currentItem.status observation is disabled)")
        }
    }
    
    func removePlayerObserver() {
        // Check isObservingPlayer flag before attempting to remove.
        // The actual removal for "currentItem.status" is commented out as it's no longer added.
        if isObservingPlayer, let queue = player.playerQueue {
            /*
            do {
                // queue.removeObserver(self, forKeyPath: "currentItem.status")
                // print("Removed player observer in ShowViewController") // Original print statement
            } catch {
                // print("Failed to remove observer: \(error)")
            }
            */
            // If this was the only observation, isObservingPlayer should be set to false here.
            // For now, we preserve the original structure for isObservingPlayer management.
            // isObservingPlayer = false // This would typically be set after successfully removing all observers.
            print("Player observer removal in ShowViewController (currentItem.status observation was disabled)")
        }
        // It's crucial to ensure isObservingPlayer is correctly managed if other KVO paths are active.
        // If 'currentItem.status' was the *only* thing being observed, then 'isObservingPlayer' should be reliably set to false here.
        // For safety, if no other observers are managed by this flag, explicitly set it false:
        // if <no_other_observers_are_active> { isObservingPlayer = false }
    }
}
