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

    //UIViewController {
    @IBOutlet weak var showDetailTableView: UITableView!
    let archiveAPI = ArchiveAPI()
    let utils = Utils()
    let network = NetworkUtility()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        if let m = player?.showModel {
            self.navigationItem.title = m.metadata?.date
        }
        self.showDetailTableView.delegate = self
        self.showDetailTableView.dataSource = self
        // self.showListTableView.rowHeight = 135.0
        getDownloadedShow()  // viewDidLoad is called after segue, so need to do this here
        miniPlayer?.newShow()
        navigationController?.delegate = self
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
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = showDetailTableView.dequeueReusableCell(withIdentifier: "ShowDetailCell", for: indexPath) as! ShowDetailTableViewCell
        guard let m = player?.showModel?.metadata else { return cell }
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = m.date
        case 1:
            cell.textLabel?.text = m.venue
        case 2:
            cell.textLabel?.text = m.description
        case 3:
            cell.textLabel?.text = m.source
        case 4:
            cell.textLabel?.text = m.transferer
        default:
            cell.textLabel?.text = ""
        }
        // if let showMDs = self.showMetadatas {

        return cell
    }
        
}
