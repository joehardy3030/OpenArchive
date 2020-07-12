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
    var year: Int?
    var month: Int?
    var archiveAPI = ArchiveAPI()
    var identifiers: [String]?
    var showMetadatas: [ShowMetadata]?
    let utils = Utils()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showListTableView.delegate = self
        self.showListTableView.dataSource = self
        self.showListTableView.rowHeight = 135.0
        utils.getMemory()
    }
        
    func getIADateRange() {
        guard let year = self.year, let month = self.month else { return }
        let url = archiveAPI.dateRangeURL(year: year, month: month)
        
        archiveAPI.getIARequestItems(url: url) {
            (response: [ShowMetadata]?) -> Void in
            
            DispatchQueue.main.async{
                if let r = response {
                    self.showMetadatas = r
                    if let s = self.showMetadatas {
                        self.showMetadatas = s.sorted(by: { $0.date! < $1.date! })
                    }
                    self.showListTableView.reloadData()
                }
            }
        }
    }

    func resetMonth() {
        self.getIADateRange()
    }
    
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
        if let target = segue.destination as? ShowViewController, let showMDs = self.showMetadatas {
            target.identifier = showMDs[indexPath.row].identifier
            target.showDate = showMDs[indexPath.row].date
        }
    }

    
}
