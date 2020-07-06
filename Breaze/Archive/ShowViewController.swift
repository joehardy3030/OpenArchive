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
    var mp3Array = [ShowMP3]()
    var showMetadata: ShowMetadataModel!
    
    
    override func viewDidLoad() {

        super.viewDidLoad()
        self.showTableView.delegate = self
        self.showTableView.dataSource = self
        self.getIAGetShowMetadata()
    }
    
    func getIAGetShowMetadata() {
        
        guard let id = self.identifier else { return }
        let url = archiveAPI.metadataURL(identifier: id)
        
        print(url)

        archiveAPI.getIARequestMetadata(url: url) {
            (response: ShowMetadataModel) -> Void in
            
            self.showMetadata = response
            if let files = self.showMetadata?.files {
                for f in files {
                    if (f.format?.contains("MP3"))! {
                        let showMP3 = ShowMP3(identifier: self.identifier, name: f.name, track: f.track)
                        print(showMP3)
                        self.mp3Array.append(showMP3)
                    }
                }
            }
            DispatchQueue.main.async{
                self.showTableView.reloadData()
                print(self.showMetadata.files_count as Any)
            }
        }
    }

        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       /*
        if let _ = self.showMetadata {
            if let count = self.showMetadata.files_count {
                return count
            }
            else { return 0 }
        }
        else { return 0 }
    */
        return self.mp3Array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = showTableView.dequeueReusableCell(withIdentifier: "ShowCell", for: indexPath) as! ShowTableViewCell
        
        /*
        if let name = self.showMetadata.files?[indexPath.row].name {
            cell.songLabel.text = name
        }
        else {
            cell.songLabel.text = "No song"
        }
        */
        
        if let name = self.mp3Array[indexPath.row].name {
            cell.songLabel.text = name
        }
        else {
            cell.songLabel.text = "no song"
        }
        
        return cell
        
    }


}
