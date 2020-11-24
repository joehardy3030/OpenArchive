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

class ShowViewController: ArchiveSuperViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var playButtonLabel: UIButton!
    @IBOutlet weak var showTableView: UITableView!
    let fileManager = FileManager.default
    var identifier: String?
    var showDate: String?
    var mp3Array = [ShowMP3]()
    var showMetadata: ShowMetadataModel!
    var isDownloaded = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.showTableView.delegate = self
        self.showTableView.dataSource = self
        
        if !isDownloaded {
            self.navigationItem.title = utils.getDateFromDateTimeString(datetime: showDate)
            getIAGetShow()
        }
        else {
            self.navigationItem.title = showDate
        }
    }
    
    @IBAction func downloadShow(_ sender: Any) {
        downloadShow()
        playButtonLabel.setTitle("Downloading", for: .normal)
    }
    
    @IBAction func shareShow(_ sender: Any) {
        shareShow()
        playButtonLabel.setTitle("Sharing", for: .normal)
    }
    
    @IBAction func playButton(_ sender: Any) {
        if playButtonLabel.currentTitle == "Play" {
            //print("Ready to play")
            player?.showModel = showMetadata // Change showMetadata to showModel for consistency
            loadDownloadedShow()  // Loads up showModel and puts it in the queue; viewDidLoad is called after segue, so need to do this here
            player?.play()
        }
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
    
    
    func getDownloadedShow() {
        if let mp3s = self.showMetadata.mp3Array {
            self.mp3Array = mp3s
        }
    }
    
    func getIAGetShow() {
        
        guard let id = self.identifier else { return }
        let url = archiveAPI.metadataURL(identifier: id)
        
        archiveAPI.getIARequestMetadata(url: url) {
            (response: ShowMetadataModel) -> Void in
            
            self.showMetadata = response
            if let files = self.showMetadata?.files {
                for f in files {
                    if (f.format?.contains("MP3"))! {
                        let showMP3 = ShowMP3(identifier: self.identifier, name: f.name, title: f.title, track: f.track)
                        self.mp3Array.append(showMP3)
                    }
                }
            }
            DispatchQueue.main.async{
                self.showTableView.reloadData()
            }
            
        }
    }
    
    func shareShow() {
        downloadShow()
        saveShareData()
    }
    
    func downloadShow() {
        for f in self.mp3Array {
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
                }
                if self.mp3Array[i].destination != nil {
                    counter += 1
                }
            }
            if self.mp3Array.count == counter {
                self.showMetadata.mp3Array = self.mp3Array
                saveDownloadData()
            }
        }
    }
    
    private func saveShareData() {
        let isPlaying = false
        var shareMetadataModel = ShareMetadataModel()
        shareMetadataModel.isPlaying = isPlaying
        shareMetadataModel.showMetadataModel = showMetadata
        let _ = network.addShareDataDoc(shareMetadataModel: shareMetadataModel)
        playButtonLabel.setTitle("Shared", for: .normal)
    }
    
    private func saveDownloadData() {
        let _ = network.addDownloadDataDoc(showMetadataModel: showMetadata)
        playButtonLabel.setTitle("Play", for: .normal)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mp3Array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = showTableView.dequeueReusableCell(withIdentifier: "ShowCell", for: indexPath) as! ShowTableViewCell
        
        if let title = self.mp3Array[indexPath.row].title, let track = self.mp3Array[indexPath.row].track {
            cell.songLabel.text = track + " " + title
        }
        else {
            cell.songLabel.text = "no song"
        }
        
        if let _ = self.mp3Array[indexPath.row].destination {
            cell.accessoryType = .checkmark
        }
        else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let indexPath = showTableView.indexPathForSelectedRow else { return }
        let songIndex = indexPath.row
        player?.showModel = showMetadata
        
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
