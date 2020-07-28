//
//  DownloadsViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/17/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit

class DownloadsViewController: ArchiveSuperViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var showListTableView: UITableView!
    //let network = NetworkUtility()
    //let utils = Utils()
    var shows: [ShowMetadataModel]?
 //   var player: AudioPlayerArchive?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showListTableView.delegate = self
        self.showListTableView.dataSource = self
        self.showListTableView.rowHeight = 135.0
        self.getDownloadedShows()
        print("view load")
        //player = AudioPlayerArchive()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.getDownloadedShows()
    }
    
    func getDownloadedShows() {
        network.getAllDownloadDocs() {
            (response: [ShowMetadataModel]?) -> Void in
            
            DispatchQueue.main.async{
                if let r = response {
                    self.shows = r
                    //if let s = self.shows {
                        //self.shows = s.sorted(by: { $0.metadata?.date! < $1.metadata?.date! })
                   // }
                    self.showListTableView.reloadData()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let s = self.shows {
            return s.count
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = showListTableView.dequeueReusableCell(withIdentifier: "ShowListCell", for: indexPath) as! ShowsListTableViewCell

        if let showMDs = self.shows {
            cell.dateLabel.text = showMDs[indexPath.row].metadata?.date
            cell.venueLabel.text = showMDs[indexPath.row].metadata?.venue
            cell.transfererLabel.text = showMDs[indexPath.row].metadata?.transferer
            cell.sourceLabel.text = showMDs[indexPath.row].metadata?.source

        }
        else {
            cell.venueLabel.text = "No show"
        }
        
        return cell
  }    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      if let mp = segue.destination as? MiniPlayerViewController {
           self.miniPlayer = mp
           print("Set the miniplayer")
           if let p = player {
               mp.player = p // There needs to be a player already for this to work. Need to inject it.
           }
       }
        
        guard let indexPath = showListTableView.indexPathForSelectedRow else { return }
        if let target = segue.destination as? DownloadPlayerViewController, let showMDs = self.shows {
            target.showModel = showMDs[indexPath.row]
            target.player = player
           // print("self player")
            target.prevController = self
        }
        else {
            print("Nope")
        }
        

    }
    //    self.present(s, animated: true)
    // }
    
}

