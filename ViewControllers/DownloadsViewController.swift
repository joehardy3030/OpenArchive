//
//  DownloadsViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/17/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit

class DownloadsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var showListTableView: UITableView!
    let network = NetworkUtility()
    let utils = Utils()
    var shows: [ShowMetadataModel]?
    var player: AudioPlayerArchive?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showListTableView.delegate = self
        self.showListTableView.dataSource = self
        self.showListTableView.rowHeight = 135.0
        self.getDownloadedShows()
    }
    
    func getDownloadedShows() {
        network.getAllDownloadDocs() {
            (response: [ShowMetadataModel]?) -> Void in
            
            DispatchQueue.main.async{
                if let r = response {
                    self.shows = r
                    //if let s = self.shows {
                    //    self.showMetadatas = s.sorted(by: { $0.date! < $1.date! })
                    //}
                    print(r)
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
        guard let indexPath = showListTableView.indexPathForSelectedRow else { return }
        if let target = segue.destination as? DownloadPlayerViewController, let showMDs = self.shows {
            target.showModel = showMDs[indexPath.row]
        }
        else {
            print("Nope")
        }
    }
    
    


}