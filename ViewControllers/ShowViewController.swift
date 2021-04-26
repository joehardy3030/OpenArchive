//
//  ShowViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/4/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

enum ShowType {
    case archive
    case downloaded
    case shared
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
    var identifier: String?
    var showDate: String?
    var mp3Array = [ShowMP3]()
    var showMetadataModel: ShowMetadataModel?
    var lastShareMetadataModel: ShareMetadataModel?
    var showType: ShowType? = .shared
    var broadcastIsPlaying: Bool = false
    var mp3index: Int = 0
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.showTableView.delegate = self
        self.showTableView.dataSource = self
        notificationCenter.addObserver(self, selector: #selector(playbackDidStart), name: .playbackStarted, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackDidPause), name: .playbackPaused, object: self.player?.playerQueue)
        
        switch showType {
        case .archive:
            self.navigationItem.title = utils.getDateFromDateTimeString(datetime: showDate)
            getIAGetShow()
        case .downloaded:
            self.navigationItem.title = showDate
            self.downloadButton.isHidden = true
            playButtonLabel.setTitle("Play", for: .normal)
        case .shared:
            self.navigationItem.title = utils.getDateFromDateTimeString(datetime: showDate)
            self.broadcastPlayPauseButton.isHidden = false
            self.shareButton.isHidden = true
            self.downloadButton.isHidden = false
            getShareSnaptshot()
        default:
            print("No show type")
        }
    }
    
    @IBAction func downloadShow(_ sender: Any) {
        switch showType {
        case .downloaded:
            print("Do nothing, for now")
        case .archive:
            if playButtonLabel.currentTitle == "Available" {
                mp3index = 0
                downloadSyncRun()
                playButtonLabel.setTitle("Downloading", for: .normal)
            }
        case .shared:
            if playButtonLabel.currentTitle == "Available" {
                mp3index = 0
                downloadSyncRun()
                playButtonLabel.setTitle("Downloading", for: .normal)
            }
        default:
            print("Do nothing by default")
        }

    }
    
    @IBAction func shareShow(_ sender: Any) {
        switch showType {
        case .downloaded:
            print("Share show from Downlaoded")
            shareShow()
        case .archive:
            playButtonLabel.setTitle("Sharing", for: .normal)
            print("Share show from archive")
            shareShow()
        case .shared:
            print("Do nothing, for now")
        default:
            print("Do nothing by default")
        }
    }
    
    @IBAction func broadcastPlayPause(_ sender: Any) {
        broadcastIsPlaying = !broadcastIsPlaying
        network.updateSharedPlayPause(broadcastIsPlaying: broadcastIsPlaying)
    }
    
    @IBAction func playButton(_ sender: Any) {
        if playButtonLabel.currentTitle == "Play" {
            playShow()
        }
    }
    
    func playShow() {
        self.player?.pause()
        self.player?.showMetadataModel = showMetadataModel // Change showMetadata to showModel for consistency
        self.loadDownloadedShow()  // Loads up showModel and puts it in the queue; viewDidLoad is called after segue, so need to do this here
        self.player?.play()
    }
    
    func loadDownloadedShow() {
        // This operation should probably belong to the player class
        if let mp3s = self.player?.showMetadataModel?.mp3Array {
            player?.cleanQueue()
            player?.loadQueuePlayer(tracks: mp3s)
        }
        //if let mp = utils.getMiniPlayerController() {
        if let mp = self.getMiniPlayerController() {
            mp.setupShow()
        }
    }
    
    func getIAGetShow() {
        
        guard let id = self.identifier else { return }
        let url = archiveAPI.metadataURL(identifier: id)
        
        archiveAPI.getIARequestMetadata(url: url) {
            (response: ShowMetadataModel) -> Void in
            
            self.showMetadataModel = response
            if let files = self.showMetadataModel?.files {
                var mp3s = [ShowMP3]()
                for f in files {
                    if (f.format?.contains("MP3"))! {
                        let showMP3 = ShowMP3(identifier: self.identifier, name: f.name, title: f.title, track: f.track)
                        mp3s.append(showMP3)
                    }
                }
                self.showMetadataModel?.mp3Array = mp3s
                self.mp3Array = mp3s
            }
            DispatchQueue.main.async{
                self.showTableView.reloadData()
            }
            
        }
    }
    
    ///Download manager class
    func getShareSnaptshot() {
        mp3index = 0
        network.getShareSnapshot() {
            (response: ShareMetadataModel?) -> Void in
            if let r = response {
                self.mp3Array = [ShowMP3]()
                self.lastShareMetadataModel = r
                self.identifier = self.lastShareMetadataModel?.showMetadataModel?.metadata?.identifier
                self.getIAGetShow()
            }
            DispatchQueue.main.async {
                print("download complete")
                self.navigationItem.title = self.lastShareMetadataModel?.showMetadataModel?.metadata?.date
                self.sharePlayPause()
                self.showTableView.reloadData()
            }
        }
    }
    
    func sharePlayPause() {
        if self.lastShareMetadataModel?.isPlaying == true {
            self.broadcastIsPlaying = true
            self.playShow()
        }
        else if self.lastShareMetadataModel?.isPlaying == false {
            self.broadcastIsPlaying = false
            self.player?.pause()
        }
    }
    
    func shareShow() {
        self.broadcastIsPlaying = false
        saveShareData()
    }
    
    private func saveShareData() {
        var saveShareMetadataModel = ShareMetadataModel()
        saveShareMetadataModel.isPlaying = broadcastIsPlaying
        saveShareMetadataModel.showMetadataModel = showMetadataModel
        let response = network.addShareDataDoc(shareMetadataModel: saveShareMetadataModel)
        print("Add share doc response: \(String(describing: response))")
        //playButtonLabel.setTitle("Play", for: .normal)
    }
    
    ///Download manager class
    func downloadShow() {
        guard let mp3s = self.showMetadataModel?.mp3Array else { return }
        for f in mp3s {
            let url = archiveAPI.downloadURL(identifier: self.identifier, filename: f.name)
            guard let localURL = self.player?.trackURLfromName(name: f.name) else { return }
            if fileManager.fileExists(atPath: localURL.path) {
                DispatchQueue.main.async{
                    self.setDownloadComplete(destination: localURL, name: f.name)
                    self.showTableView.reloadData()
                }
            }
            else {
                archiveAPI.getIADownload(url: url) {
                    (response: URL?) -> Void in
                    DispatchQueue.main.async{
                        self.setDownloadComplete(destination: response, name: f.name)
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
        }  ///  mp3index += mp3index
    
        else {
            print("all done here")
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
            player?.pause()
            player?.cleanQueue()
            player?.showMetadataModel = showMetadataModel // Change showMetadata to showModel for consistency
            player?.getTrackItemAndPrepareToPlay(track: mp3)
            player?.loadQueuePlayerTrack()
            if let mp = self.getMiniPlayerController() {
                mp.setupShow()
            }
        }
        else {
            player?.getTrackItemAndPrepareToPlay(track: mp3)
        }
        
    }
    
    ///Download manager class
    func downloadSong(showMP3: ShowMP3?, completion: @escaping (URL?) -> Void) {
        guard let s = showMP3 else { return }
        let url = archiveAPI.downloadURL(identifier: self.identifier, filename: s.name)
        guard let localURL = utils.trackURLfromName(name: s.name) else { return }
        if fileManager.fileExists(atPath: localURL.path) {
            completion(localURL)
        }
        else {
            archiveAPI.getIADownload(url: url) {
                (response: URL?) -> Void in
                completion(response)
            }
        }
    }
                
    ///Download manager class
    private func setDownloadComplete(destination: URL?, name: String?) {
        var counter = 0
        if let d = destination {
            for i in 0...(self.mp3Array.count - 1) {
                if self.mp3Array[i].name == name {
                    self.mp3Array[i].destination = d
                    self.showMetadataModel?.mp3Array?[i].destination = d
                }
                if self.mp3Array[i].destination != nil {
                    counter += 1
                }
            }
            if self.mp3Array.count == counter {
                if (showType == .shared) {
                    self.lastShareMetadataModel?.showMetadataModel?.mp3Array = self.mp3Array
                    self.showMetadataModel = self.lastShareMetadataModel?.showMetadataModel
                }
                //self.showMetadataModel?.mp3Array = self.mp3Array
                saveDownloadData()
            }
        }
        print("Set download complete")
    }
    
    private func saveDownloadData() {
        let _ = network.addDownloadDataDoc(showMetadataModel: showMetadataModel)
        print("Save download data")
        playButtonLabel.setTitle("Play", for: .normal)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = showMetadataModel?.mp3Array?.count {
            return (6 + count)
        }
        else {
            return 6
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = showTableView.dequeueReusableCell(withIdentifier: "ShowDetailCell", for: indexPath) as! ShowDetailTableViewCell
        
        guard let mp3s = self.showMetadataModel?.mp3Array,
              let m = self.showMetadataModel?.metadata
              else { return UITableViewCell() }
        let idx = indexPath.row - 6
        cell.accessoryType = .none

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = m.date
        case 1:
            cell.textLabel?.text = m.venue
        case 2:
            cell.textLabel?.text = m.coverage
        case 3:
            cell.textLabel?.text = m.description
        case 4:
            cell.textLabel?.text = m.source
        case 5:
            cell.textLabel?.text = m.transferer
        default:
            if let title = mp3s[idx].title,
               let track = mp3s[idx].track {
                cell.textLabel?.text = track + " " + title
            }
            else {
                cell.textLabel?.text = "no song"
            }
            
            if let _ = mp3s[idx].destination {
                cell.accessoryType = .checkmark
            }
            else {
                cell.accessoryType = .none
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let indexPath = showTableView.indexPathForSelectedRow else { return }
        let songIndex = indexPath.row
        player?.showMetadataModel = showMetadataModel
        
        DispatchQueue.main.async{
            
            if let mp3s = self.player?.showMetadataModel?.mp3Array {
                if let trackURL = self.player?.trackURLfromName(name: mp3s[songIndex].name) {
                    do {
                        let available = try trackURL.checkResourceIsReachable()
                        print(available)
                        
                    }
                    catch {
                        print("No song")
                    }
                }
                
            }
            
        }
    }
}

@available(iOS 13.0, *)
private extension ShowViewController {
    @objc private func playbackDidStart(_ notification: Notification) {
        print("Item playing")
    }
    
    @objc private func playbackDidPause(_ notification: Notification) {
        print("Item paused")
    }
}
/*
@available(iOS 13.0, *)
private extension ShowViewController {
    func getMiniPlayerController() -> MiniPlayerViewController? {
        guard let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate else { return nil }
        //guard let sceneDelegate = UIApplication.shared.delegate as? SceneDelegate else { return nil }
        
        //guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        //if let vcs = appDelegate.window?.rootViewController?.children
        
        if let vcs = sceneDelegate.window?.rootViewController?.children
        {
            for vc in vcs {
                if let mp = vc as? MiniPlayerViewController {
                    return mp
                }
            }
        }
        return nil
    }
}
*/
