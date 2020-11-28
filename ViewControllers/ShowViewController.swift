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

class ShowViewController: ArchiveSuperViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var playButtonLabel: UIButton!
    @IBOutlet weak var showTableView: UITableView!
    @IBOutlet weak var broadcastPlayPauseButton: UIButton!
    let fileManager = FileManager.default
    var identifier: String?
    var showDate: String?
    var mp3Array = [ShowMP3]()
    var showMetadataModel: ShowMetadataModel?
    var lastShareMetadataModel: ShareMetadataModel?
    var showType: ShowType? = .shared
    var broadcastIsPlaying: Bool = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.showTableView.delegate = self
        self.showTableView.dataSource = self
        
        switch showType {
        case .archive:
            self.navigationItem.title = utils.getDateFromDateTimeString(datetime: showDate)
            getIAGetShow()
        case .downloaded:
            self.navigationItem.title = showDate
            //self.shareButton.isEnabled = false
            //self.downloadButton.isEnabled = false
            //self.shareButton.isHidden = true
            self.downloadButton.isHidden = true
            playButtonLabel.setTitle("Play", for: .normal)
        case .shared:
            self.navigationItem.title = utils.getDateFromDateTimeString(datetime: showDate)
            //self.shareButton.isEnabled = false
            self.broadcastPlayPauseButton.isHidden = false
            self.shareButton.isHidden = true
            self.downloadButton.isHidden = true
            getShareSnaptshot()
        default:
            print("No show type")
        }
    }
    
    /*
    override func viewWillAppear(_ animated: Bool) {
        if (showType == .shared) && (self.lastShareMetadataModel?.isPlaying == true) {
            playShow()
        }
    }
    */
    
    @IBAction func downloadShow(_ sender: Any) {
        switch showType {
        case .downloaded:
            print("Do nothing, for now")
        case .archive:
            downloadShow()
            playButtonLabel.setTitle("Downloading", for: .normal)
        case .shared:
            downloadShow()
            playButtonLabel.setTitle("Downloading", for: .normal)
        default:
            print("Do nothing by default")
        }

    }
    
    @IBAction func shareShow(_ sender: Any) {
        switch showType {
        case .downloaded:
            playButtonLabel.setTitle("Sharing", for: .normal)
            shareShow()
        case .archive:
            playButtonLabel.setTitle("Sharing", for: .normal)
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
        playShow()
    }
    
    func playShow() {
        if playButtonLabel.currentTitle == "Play" {
            player?.showModel = showMetadataModel // Change showMetadata to showModel for consistency
            loadDownloadedShow()  // Loads up showModel and puts it in the queue; viewDidLoad is called after segue, so need to do this here
            player?.play()
        }
       // if showType == .shared {
           // lastShareMetadataModel?.isPlaying = true
          //  saveShareData(isPlaying: true)
       // }
    }
    
    func loadDownloadedShow() {
        // This operation should probably belong to the player class
        if let mp3s = self.player?.showModel?.mp3Array {
            if (player?.playerItems.count)! > 0 {
                player?.playerItems = [AVPlayerItem]()
            }
            player?.loadQueuePlayer(tracks: mp3s)
        }
        if let mp = utils.getMiniPlayerController() {
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
    
    func getShareSnaptshot() {
        network.getShareSnapshot() {
            (response: ShareMetadataModel?) -> Void in
                if let r = response {
                    self.mp3Array = [ShowMP3]()
                    self.lastShareMetadataModel = r
                    if let files = self.lastShareMetadataModel?.showMetadataModel?.files,
                        let id = self.lastShareMetadataModel?.showMetadataModel?.metadata?.identifier {
                        
                        for f in files {
                            if (f.format?.contains("MP3"))! {
                                let showMP3 = ShowMP3(identifier: id, name: f.name, title: f.title, track: f.track)
                                self.mp3Array.append(showMP3)
                                if let localURL = self.player?.trackURLfromName(name: f.name) {
                                    let fileManager = FileManager.default
                                    if fileManager.fileExists(atPath: localURL.path) {
                                        DispatchQueue.main.async{
                                            //self.setDownloadComplete(destination: localURL, name: f.name, available: true)
                                            self.setDownloadComplete(destination: localURL, name: f.name)
                                            self.showTableView.reloadData()
                                        }
                                        print("FILE AVAILABLE")
                                    } else {
                                        let archiveURL = self.archiveAPI.downloadURL(identifier: id, filename: f.name)
                                        self.archiveAPI.getIADownload(url: archiveURL) {
                                               (response: URL?) -> Void in
                                               DispatchQueue.main.async{
                                                    self.playButtonLabel.setTitle("Downloading", for: .normal)
                                                    //self.setDownloadComplete(destination: response, name: f.name, available: false)
                                                    self.setDownloadComplete(destination: response, name: f.name)
                                                    self.showTableView.reloadData()
                                               }
                                           }
                                        print("FILE NOT AVAILABLE")
                                    }
                                }
                            }
                        }
                    }
                    DispatchQueue.main.async{
                        print("download complete")
                        self.showMetadataModel = self.lastShareMetadataModel?.showMetadataModel
                        self.navigationItem.title = self.lastShareMetadataModel?.showMetadataModel?.metadata?.date
                        if self.lastShareMetadataModel?.isPlaying == true {
                            self.broadcastIsPlaying = true
                            self.playShow()
                        }
                        else if self.lastShareMetadataModel?.isPlaying == false {
                            self.broadcastIsPlaying = false
                            self.player?.pause()
                        }
                        self.showTableView.reloadData()
                    }
                }
            }
    }
    
    func shareShow() {
        switch showType {
        case .archive:
            if playButtonLabel.currentTitle != "Play" {
                downloadShow()
            }
            saveShareData(broadcastIsPlaying: false)
        case .downloaded:
            saveShareData(broadcastIsPlaying: false)
            //playButtonLabel.setTitle("Play", for: .normal)
        default:
            print("Do nothing")
        }
    }
    
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
    }
    
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
    }
    /*
    private func setDownloadComplete(destination: URL?, name: String?, available: Bool) {
        var counter = 0
        if let d = destination {
            for i in 0...(self.mp3Array.count - 1) {
                if self.mp3Array[i].name == name {
                    self.mp3Array[i].destination = d
                    //self.showMetadataModel?.mp3Array?[i].destination = d
                }
                if self.mp3Array[i].destination != nil {
                    counter += 1
                }
            }
            if self.mp3Array.count == counter {
                self.lastShareMetadataModel?.showMetadataModel?.mp3Array = self.mp3Array
                self.showMetadataModel?.mp3Array = self.mp3Array
                //print(self.playButton.titleLabel?.text)
                //if !available {
                    saveDownloadData()
                //}
                print("save downloaded data")
                self.playButtonLabel.setTitle("Play", for: .normal)
            }
        }
    }
    */
    
    private func saveShareData(broadcastIsPlaying: Bool) {
        var saveShareMetadataModel = ShareMetadataModel()
        saveShareMetadataModel.isPlaying = broadcastIsPlaying
        saveShareMetadataModel.showMetadataModel = showMetadataModel
        let response = network.addShareDataDoc(shareMetadataModel: saveShareMetadataModel)
        print("Add share doc response: \(String(describing: response))")
        playButtonLabel.setTitle("Play", for: .normal)
    }
    
    private func saveDownloadData() {
        let _ = network.addDownloadDataDoc(showMetadataModel: showMetadataModel)
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
        player?.showModel = showMetadataModel
        
        DispatchQueue.main.async{
            
            if let mp3s = self.player?.showModel?.mp3Array {
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
