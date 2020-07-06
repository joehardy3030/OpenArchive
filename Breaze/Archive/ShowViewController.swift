//
//  ShowViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/4/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit

class ShowViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var showTableView: UITableView!
    var identifier: String?
    let archiveAPI = ArchiveAPI()
    let avPlayer = AudioPlayerArchive()
    var mp3Array = [ShowMP3]()
    var showMetadata: ShowMetadataModel!

    override func viewDidLoad() {

        super.viewDidLoad()
        self.showTableView.delegate = self
        self.showTableView.dataSource = self
        self.getIAGetShow()
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
                        let showMP3 = ShowMP3(identifier: self.identifier, name: f.name, track: f.track)
                        self.mp3Array.append(showMP3)
                    }
                }
            }
            
            self.downloadShow()
            
            DispatchQueue.main.async{
                self.showTableView.reloadData()
                print(self.showMetadata.files_count as Any)
            }
        }
    }
    
    func downloadShow() {
        for f in self.mp3Array {
            let url = archiveAPI.downloadURL(identifier: self.identifier, filename: f.name)
            archiveAPI.getIADownload(url: url) {
                (response: URL?) -> Void in
                DispatchQueue.main.async{
                    self.setDestination(destination: response, name: f.name)
                    self.showTableView.reloadData()
                }
            }
        }
    }
    
    func setDestination(destination: URL?, name: String?) {
        if let d = destination {
            for i in 0...(self.mp3Array.count - 1) {
                if self.mp3Array[i].name == name {
                    self.mp3Array[i].destination = d
                }
            }
        }
    }
    
    /*
    self.present(playerViewController, animated: true) {
          if let avp = self.avPlayer {
              avp.play()
          }
      }
    */
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mp3Array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = showTableView.dequeueReusableCell(withIdentifier: "ShowCell", for: indexPath) as! ShowTableViewCell
        
        if let name = self.mp3Array[indexPath.row].name {
            cell.songLabel.text = name
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
        //if let cell = yearTableView.cellForRow(at: indexPath as IndexPath) {
        if let url = self.mp3Array[indexPath.row].destination {
            if let player = self.avPlayer.avPlayer {
                if player.rate > 0.0 {
                    player.pause()
                }
            }
            else {
                self.avPlayer.playAudioFile(url: url)
            }
            //    self.avPlayer.pause()
            //}
           // else{
//                self.avPlayer.playAudioFile(url: url)
           // }
        }
        
        //playAudioFile(url: url)
        //playAudioFileController(url: url)
    }

}
