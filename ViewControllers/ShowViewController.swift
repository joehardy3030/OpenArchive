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
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.showTableView.delegate = self
        self.showTableView.dataSource = self
        notificationCenter.addObserver(self, selector: #selector(playbackDidStart), name: .playbackStarted, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackDidPause), name: .playbackPaused, object: self.player.playerQueue)
        notificationCenter.addObserver(self, selector: #selector(playbackDidFail), name: .playbackFailed, object: nil)
        self.navigationItem.title = "";
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

    func streamShow() {
        self.player.pause()
        self.player.showMetadataModel = showMetadataModel // Change showMetadata to showModel for consistency
        self.loadStreamingShow()  // Loads up showModel and puts it in the queue; viewDidLoad is called after segue, so need to do this here
        self.player.play()
    }

    func playShow() {
        self.player.pause()
        self.player.showMetadataModel = showMetadataModel // Change showMetadata to showModel for consistency
        self.loadDownloadedShow()  // Loads up showModel and puts it in the queue; viewDidLoad is called after segue, so need to do this here
        self.player.play()
    }

    func loadStreamingShow() {
        // This operation should probably belong to the player class
        if let _ = self.player.showMetadataModel?.mp3Array {
            player.loadStreamingQueuePlayer()
        }
        if let mp = self.getMiniPlayerController() {
            mp.setupShow()
        }
        setupPlayerObserver()
    }
    
    func loadDownloadedShow() {
        // This operation should probably belong to the player class
        if let mp3s = self.player.showMetadataModel?.mp3Array {
            player.loadQueuePlayer(tracks: mp3s)
        }
        if let mp = self.getMiniPlayerController() {
            mp.setupShow()
        }
        setupPlayerObserver()
    }
    
    func getIAGetShow() {
        
        guard let id = self.showMetadata?.identifier else { return }
        let url = archiveAPI.metadataURL(identifier: id)
        archiveAPI.getIARequestMetadataDecodable(url: url) {
            (response: ShowMetadataModel) -> Void in
            self.showMetadataModel = response
            if let ar = self.showMetadata?.avg_rating, let nr = self.showMetadata?.num_reviews {
                self.showMetadataModel?.metadata?.avg_rating = ar
                self.showMetadataModel?.metadata?.num_reviews = nr
            }
            if let files = self.showMetadataModel?.files {
                print(files)
                var mp3s = [ShowMP3]()
                for f in files {
                    if (f.format?.contains("MP3"))! {
                        let showMP3 = ShowMP3(identifier: self.showMetadata?.identifier, name: f.name, title: f.title, track: f.track)
                        mp3s.append(showMP3)
                    }
                }
                self.showMetadataModel?.mp3Array = mp3s
            }
            DispatchQueue.main.async{
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
        guard let s = showMP3 else { return }
        let url = archiveAPI.downloadURL(identifier: self.showMetadata?.identifier, filename: s.name)
        guard let localURL = utils.trackURLfromName(name: s.name) else { return }
        if fileManager.fileExists(atPath: localURL.path) {
            completion(localURL)
        }
        else {
            archiveAPI.getIADownload(url: url, progressHandler: { (progress) in
                self.downloadProgress[localURL] = progress
                
                // Find the index of this track and reload just that row for performance
                if let mp3s = self.showMetadataModel?.mp3Array {
                    for (index, mp3) in mp3s.enumerated() {
                        if mp3.name == s.name {
                            DispatchQueue.main.async {
                                let indexPath = IndexPath(row: index, section: 2) // Section 2 is tracks
                                self.showTableView.reloadRows(at: [indexPath], with: .none)
                            }
                            break
                        }
                    }
                }
            }) { 
                (localFileURL: URL?, error: Error?) -> Void in
                if let error = error {
                    print("Error downloading \(s.name ?? "unknown file"): \(error.localizedDescription)")
                    // Remove from progress dictionary on error
                    self.downloadProgress.removeValue(forKey: localURL)
                    return
                }
                
                // On successful download, update UI
                if let mp3s = self.showMetadataModel?.mp3Array {
                    for (index, mp3) in mp3s.enumerated() {
                        if mp3.name == s.name {
                            DispatchQueue.main.async {
                                let indexPath = IndexPath(row: index, section: 2)
                                self.showTableView.reloadRows(at: [indexPath], with: .automatic)
                            }
                            break
                        }
                    }
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
        print("select current track \(index)")
        let indexPath = IndexPath(item: index, section: 2)
        self.showTableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableView.ScrollPosition.middle)
    }
    
    override func handlePlayerReadyToPlay() {
        selectCurrentTrack()
        print("ready to play in ShowViewController")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
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
                handlePlayerReadyToPlay()
            case .failed:
                // This is now handled by the .playbackFailed notification
                break
            case .unknown:
                print("unknown status")
            default:
                print("nope")
            }
        }
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
            // case 3 was m.source, now moved
            case 3: // Was case 4
                cell.textLabel?.text = m.transferer
            default:
                break
            }
        case 1: // Taper's Notes Section (only reached if isDescriptionExpanded is true)
            if indexPath.row == 0 { // Source row
                cell.textLabel?.text = m.source
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
                if let localURL = utils.trackURLfromName(name: track.name) {
                    // Check if already downloaded
                    if track.destination != nil || FileManager.default.fileExists(atPath: localURL.path) {
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
            // For streaming, just play the show starting from selected track
            streamShow()
            for _ in 0..<songIndex {
                player.playerQueue?.advanceToNextItem()
            }
        } else {
            // For downloaded files, check if track exists locally
            if let trackURL = utils.trackURLfromName(name: showMetadataModel?.mp3Array?[songIndex].name) {
                do {
                    let _ = try trackURL.checkResourceIsReachable()
                    print("playShow")
                    playShow()
                    for _ in 0..<songIndex {
                        player.playerQueue?.advanceToNextItem()
                    }
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
}

@available(iOS 13.0, *)
private extension ShowViewController {
    // Override notification handlers from the base class
    override func playbackDidStart(_ notification: Notification) {
        // Update play button UI
        if #available(iOS 13.0, *) {
            broadcastPlayPauseButton.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal)
        } else {
            broadcastPlayPauseButton.setTitle("Pause", for: .normal)
        }
        broadcastIsPlaying = true
    }
    
    override func playbackDidPause(_ notification: Notification) {
        // Update play button UI
        if #available(iOS 13.0, *) {
            broadcastPlayPauseButton.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
        } else {
            broadcastPlayPauseButton.setTitle("Play", for: .normal)
        }
        broadcastIsPlaying = false
    }
}
