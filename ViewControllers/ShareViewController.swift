//
//  ShareViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 8/11/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import AVKit

class ShareViewController: ArchiveSuperViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var sharedShowTableView: UITableView!
    var shareMetadataModels: [ShareMetadataModel]?
    var lastShareMetadataModel: ShareMetadataModel?
    var mp3Array = [ShowMP3]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sharedShowTableView.delegate = self
        sharedShowTableView.dataSource = self
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getSharedShow()
    }
    
    func getSharedShow() {
        network.getSharedDoc() {
            (response: [ShareMetadataModel]?) -> Void in
            if let r = response {
                self.shareMetadataModels = r
                self.lastShareMetadataModel = r.last
                if let files = self.lastShareMetadataModel?.showMetadataModel?.files,
                    let id = self.lastShareMetadataModel?.showMetadataModel?.metadata?.identifier {
                    
                    for f in files {
                        if (f.format?.contains("MP3"))! {
                            let showMP3 = ShowMP3(identifier: id, name: f.name, title: f.title, track: f.track)
                            self.mp3Array.append(showMP3)
                            if let url = self.player?.trackURLfromName(name: f.name) {
                                let fileManager = FileManager.default
                                if fileManager.fileExists(atPath: url.absoluteString) {
                                      print("FILE AVAILABLE")
                                  } else {
                                      print("FILE NOT AVAILABLE")
                                  }
                            }
                        }
                    }
                }
                self.lastShareMetadataModel?.showMetadataModel?.mp3Array = self.mp3Array
            }
            DispatchQueue.main.async{
                self.sharedShowTableView.reloadData()
            }
        }
    }

    func loadDownloadedShow() {
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
    
    
    func downloadShow() {
        guard let id = self.lastShareMetadataModel?.showMetadataModel?.metadata?.identifier else { return }
        for f in self.mp3Array {
            let url = archiveAPI.downloadURL(identifier: id, filename: f.name)
            archiveAPI.getIADownload(url: url) {
                (response: URL?) -> Void in
                DispatchQueue.main.async{
                    self.setDownloadComplete(destination: response, name: f.name)
                    self.sharedShowTableView.reloadData()
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
                self.lastShareMetadataModel?.showMetadataModel?.mp3Array = self.mp3Array
                //saveDownloadData()
            }
        }
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
