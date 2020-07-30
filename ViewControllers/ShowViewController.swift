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
    
    @IBOutlet weak var availableLabel: UILabel!
    @IBOutlet weak var showTableView: UITableView!
    var identifier: String?
    var showDate: String?
  //  let archiveAPI = ArchiveAPI()
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
        availableLabel.text = "Downloading"
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
    
    func downloadShow() {
        for f in self.mp3Array {
            let url = archiveAPI.downloadURL(identifier: self.identifier, filename: f.name)
            archiveAPI.getIADownload(url: url) {
                (response: URL?) -> Void in
                DispatchQueue.main.async{
                    self.setDownloadComplete(destination: response, name: f.name)
                    self.showTableView.reloadData()
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
    
     private func saveDownloadData() {
        let _ = network.addDownloadDataDoc(showMetadataModel: showMetadata)
        availableLabel.text = "Downloaded"
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

    }

}
