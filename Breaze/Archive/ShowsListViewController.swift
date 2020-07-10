//
//  ShowsListViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/4/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import SwiftyJSON

class ShowsListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var showListTableView: UITableView!
   // var numShows: Int = 1
    var year: Int?
    var month: Int?
    var archiveAPI = ArchiveAPI()
    var identifiers: [String]?
    var showMetadatas: [ShowMetadata]?
    let utils = Utils()
   // var selectedIdentifier: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showListTableView.delegate = self
        self.showListTableView.dataSource = self
        self.showListTableView.rowHeight = 135.0
        utils.getMemory()
       // self.getIADateRange()
        // Do any additional setup after loading the view.
    }
    
   // func viewWillAppear() {
    //    self.getIADateRange()
   // }
    
    func getIADateRange() {
        guard let year = self.year, let month = self.month else { return }
        let url = archiveAPI.dateRangeURL(year: year, month: month)
        
        print(url)

        archiveAPI.getIARequestItems(url: url) {
            (response: [ShowMetadata]?) -> Void in
            
            DispatchQueue.main.async{
                if let r = response {
                    self.showMetadatas = r
                    if let s = self.showMetadatas {
                        self.showMetadatas = s.sorted(by: { $0.date! < $1.date! })
                    }
                    self.showListTableView.reloadData()
                   // print(self.showMetadatas)
                }
            }
        }
    }

    func resetMonth() {
        self.getIADateRange()
    }
    /*
    func getIAGetShow() {
        
        guard let id = self.identifier else { return }
        let url = archiveAPI.metadataURL(identifier: id)
    
        archiveAPI.getIARequestMetadata(url: url) {
            (response: ShowMetadataModel) -> Void in
            
            self.showMetadata = response
            if let files = self.showMetadata?.files {
                for f in files {
                    if (f.format?.contains("MP3"))! {
                        print(f.format as Any)
                        let showMP3 = ShowMP3(identifier: self.identifier, name: f.name, title: f.title, track: f.track)
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
    */
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let showMDs = self.showMetadatas {
            return showMDs.count
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = showListTableView.dequeueReusableCell(withIdentifier: "ShowListCell", for: indexPath) as! ShowsListTableViewCell

        if let showMDs = self.showMetadatas {
            //self.selectedIdentifier = ids[indexPath.row]
            //cell.identifierLabel.text = showMDs[indexPath.row].identifier
            cell.dateLabel.text = utils.getDateFromDateTimeString(datetime: showMDs[indexPath.row].date)
            cell.venueLabel.text = showMDs[indexPath.row].venue
            cell.transfererLabel.text = showMDs[indexPath.row].transferer
            cell.sourceLabel.text = showMDs[indexPath.row].source

        }
        else {
            cell.venueLabel.text = "No show"
        }
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = showListTableView.indexPathForSelectedRow else { return }
        guard let ids = self.identifiers else { return }
        if let target = segue.destination as? ShowViewController {
            target.identifier = ids[indexPath.row]
        }
    }

    
}
