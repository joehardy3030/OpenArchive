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
    var showMetadataModel: ShowMetadataModel?
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
            player?.showModel = showMetadataModel // Change showMetadata to showModel for consistency
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
    
    
    //func getDownloadedShow() {
    //    if let mp3s = self.showMetadataModel?.mp3Array {
    //        self.mp3Array = mp3s
     //   }
   // }
    
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
                       // self.mp3Array.append(showMP3)
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
    
    func shareShow() {
        downloadShow()
        saveShareData()
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
                    print(self.mp3Array[i].name)
                    self.mp3Array[i].destination = d
                    self.showMetadataModel?.mp3Array?[i].destination = d
                }
                if self.mp3Array[i].destination != nil {
                    counter += 1
                    print("counter \(counter)")
                }
            }
            if self.mp3Array.count == counter {
                //self.showMetadataModel?.mp3Array = self.mp3Array
                saveDownloadData()
            }
        }
    }
    
    private func saveShareData() {
        let isPlaying = false
        var shareMetadataModel = ShareMetadataModel()
        shareMetadataModel.isPlaying = isPlaying
        shareMetadataModel.showMetadataModel = showMetadataModel
        let _ = network.addShareDataDoc(shareMetadataModel: shareMetadataModel)
        playButtonLabel.setTitle("Shared", for: .normal)
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
        /*
        if let count = showMetadataModel?.mp3Array?.count {
            print("Count \(count)")
            return count
        }
        else {
            return 0
        }
        */
        //return showMetadataModel?.mp3Array?.count
        //return self.mp3Array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = showTableView.dequeueReusableCell(withIdentifier: "ShowDetailCell", for: indexPath) as! ShowDetailTableViewCell
        
        guard let mp3s = self.showMetadataModel?.mp3Array,
              let m = self.showMetadataModel?.metadata
              else { return UITableViewCell() }
        let idx = indexPath.row - 6

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
