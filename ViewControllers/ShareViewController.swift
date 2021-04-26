//
//  ShareViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 8/11/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import AVKit
import FirebaseFirestore
import CodableFirebase

@available(iOS 13.0, *)
class ShareViewController: ArchiveSuperViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var sharedShowTableView: UITableView!
    var lastShareMetadataModel: ShareMetadataModel?
    var mp3Array = [ShowMP3]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sharedShowTableView.delegate = self
        sharedShowTableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadShareSnaptshot()
        self.sharedShowTableView.reloadData()
    }
    
    @IBAction func playButtonPress(_ sender: Any) {
        guard let showModel = lastShareMetadataModel?.showMetadataModel else { return }
        player?.showMetadataModel = showModel
        loadDownloadedShow()  // Loads up showModel and puts it in the queue; viewDidLoad is called after segue, so need to do this here
        player?.play()
        
    }
    
    func loadShareSnaptshot() {
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
                                            self.setDownloadComplete(destination: localURL, name: f.name, available: true)
                                            self.sharedShowTableView.reloadData()
                                        }
                                        print("FILE AVAILABLE")
                                    } else {
                                        let archiveURL = self.archiveAPI.downloadURL(identifier: id, filename: f.name)
                                        self.archiveAPI.getIADownload(url: archiveURL) {
                                               (response: URL?) -> Void in
                                               DispatchQueue.main.async{
                                                   self.playButton.setTitle("Downloading", for: .normal)
                                                   self.setDownloadComplete(destination: response, name: f.name, available: false)
                                                   self.sharedShowTableView.reloadData()
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
                        self.navigationItem.title = self.lastShareMetadataModel?.showMetadataModel?.metadata?.date
                        self.sharedShowTableView.reloadData()
                    }
                }
            }
    }
    
    func loadDownloadedShow() {
        if let mp3s = self.player?.showMetadataModel?.mp3Array {
            player?.cleanQueue()
            player?.loadQueuePlayer(tracks: mp3s)
         }
        if let mp = self.getMiniPlayerController() {
            mp.setupShow()
        }
     }
    
    
    func downloadShow() {
        guard let id = self.lastShareMetadataModel?.showMetadataModel?.metadata?.identifier else { return }
        for f in self.mp3Array {
            let url = archiveAPI.downloadURL(identifier: id, filename: f.name)
            archiveAPI.getIADownload(url: url) {
                (response: URL?) -> Void in
                DispatchQueue.main.async{
                    self.setDownloadComplete(destination: response, name: f.name, available: false)
                    self.sharedShowTableView.reloadData()
                }
            }
        }
    }

    private func setDownloadComplete(destination: URL?, name: String?, available: Bool) {
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
                self.lastShareMetadataModel?.showMetadataModel?.mp3Array = self.mp3Array
                //print(self.playButton.titleLabel?.text)
                if !available {
                    saveDownloadData()
                }
                self.playButton.setTitle("Play", for: .normal)
            }
        }
    }

    private func saveDownloadData() {
        let _ = network.addDownloadDataDoc(showMetadataModel: lastShareMetadataModel?.showMetadataModel)
    //    availableLabel.text = "Downloaded"
    }

    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = lastShareMetadataModel?.showMetadataModel?.mp3Array?.count {
            return (6 + count)
        }
        else {
            return 6
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = sharedShowTableView.dequeueReusableCell(withIdentifier: "ShowDetailCell", for: indexPath) as! ShowDetailTableViewCell
        guard let m = lastShareMetadataModel?.showMetadataModel?.metadata else { return cell }
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
                if let mp3s = lastShareMetadataModel?.showMetadataModel?.mp3Array {
                let idx = indexPath.row - 6
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
            }

            return cell
        }
}
