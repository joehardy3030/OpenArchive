//
//  DownloadPlayerViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/19/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

@available(iOS 13.0, *)
class DownloadPlayerViewController: ArchiveSuperViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var showDetailTableView: UITableView!
    var showModel: ShowMetadataModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Show Details"
        self.showDetailTableView.delegate = self
        self.showDetailTableView.dataSource = self
    }
    
    @IBAction func playButtonPress(_ sender: Any) {
        player.showMetadataModel = showModel
        loadDownloadedShow()  // Loads up showModel and puts it in the queue; viewDidLoad is called after segue, so need to do this here
        player.play()
    }
    
    func loadDownloadedShow() {
        // This operation should probably belong to the player class
        if let mp3s = self.player.showMetadataModel?.mp3Array {
            player.loadQueuePlayer(tracks: mp3s)
         }
        if let mp = self.getMiniPlayerController() {
            mp.setupShow()
        }
     }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = showModel?.mp3Array?.count {
            return (6 + count)
        }
        else {
            return 6
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = showDetailTableView.dequeueReusableCell(withIdentifier: "ShowDetailCell", for: indexPath) as! ShowDetailTableViewCell
        guard let m = showModel?.metadata else { return cell }
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
            if let mp3s = showModel?.mp3Array {
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
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let indexPath = showDetailTableView.indexPathForSelectedRow else { return }
        
        if indexPath.row >= 6 {
            print(indexPath.row)
            let songIndex = indexPath.row - 6
            player.showMetadataModel = showModel
            
            DispatchQueue.main.async{
                
                if let mp3s = self.player.showMetadataModel?.mp3Array {
                    if let trackURL = self.player.trackURLfromName(name: mp3s[songIndex].name) {
                        do {
                            let available = try trackURL.checkResourceIsReachable()
                            print(available)
                        }
                        catch {
                            print(error)
                        }
                    }
                }
            }
        }
    }
}
