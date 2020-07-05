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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showListTableView.delegate = self
        self.showListTableView.dataSource = self
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

        archiveAPI.getIARequest(url: url) {
            (response: [String]?) -> Void in
            
            DispatchQueue.main.async{
                if let r = response {
                    self.identifiers = r
                    self.showListTableView.reloadData()
                    //print(self.identifiers)
                }
            }
        }
    }

    func resetMonth() {
        self.getIADateRange()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let ids = self.identifiers {
            return ids.count
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = showListTableView.dequeueReusableCell(withIdentifier: "ShowListCell", for: indexPath) as! ShowsListTableViewCell
      /*  if let y = self.year {
            if let m = self.month {
                cell.identifierLabel.text = String(y) + "-" + String(m)
            }
        }
        */
        if let ids = self.identifiers {
            cell.identifierLabel.text = ids[indexPath.row]
        }
        else {
            cell.identifierLabel.text = "No shows"
        }
        return cell
        
    }
    
}
