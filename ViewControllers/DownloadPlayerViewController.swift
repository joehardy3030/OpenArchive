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

class DownloadPlayerViewController: ArchiveSuperViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var showDetailTableView: UITableView!
    var showModel: ShowMetadataModel?
    let archiveAPI = ArchiveAPI()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        if let m = player?.showModel {
            self.navigationItem.title = m.metadata?.date
        }
        self.showDetailTableView.delegate = self
        self.showDetailTableView.dataSource = self
       // navigationController?.delegate = self
    }
    
     override func viewWillAppear(_ animated: Bool) {
            if let p = player {
                print(p)
                print("Player is being set")
            }
            
            if let mp = miniPlayer {
    //            mp.player = p
                print(mp)
                print("miniplayer is being set")
            }
            //print(player)
            //print(miniPlayer?.player)
            //print(player?.showModel?.metadata?.coverage)
            
            //miniPlayer?.setupShow()
            //print("Will appear")
        }
    /*
    override func viewWillAppear(_ animated: Bool) {
        if player?.playerQueue?.rate ?? 0.0 > 0.0 {
            playButton.isHidden = true
        }
        else {
            playButton.isHidden = false
        }

    }
    */
    
    @IBAction func playButtonPress(_ sender: Any) {
        player?.showModel = showModel
        //miniPlayer?.player?.showModel = showModel
        getDownloadedShow()  // viewDidLoad is called after segue, so need to do this here
        player?.play()
        //player?.setupShow()
        
        //miniPlayer?.setupShow()
        //miniPlayer?.playPause()
    }
    
    func getDownloadedShow() {
        if let mp3s = self.player?.showModel?.mp3Array {
            if (player?.playerItems.count)! > 0 {
                player?.playerItems = [AVPlayerItem]()
            }
            player?.loadQueuePlayer(tracks: mp3s)
         }
     }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = showDetailTableView.dequeueReusableCell(withIdentifier: "ShowDetailCell", for: indexPath) as! ShowDetailTableViewCell
        guard let m = showModel?.metadata else { return cell }
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
            cell.textLabel?.text = ""
        }
        // if let showMDs = self.showMetadatas {

        return cell
    }
        
}
