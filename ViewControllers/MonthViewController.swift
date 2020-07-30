//
//  MonthViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/2/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit

class MonthViewController: ArchiveSuperViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var monthTableView: UITableView!
    var months: [String] = []
    var year: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.monthTableView.delegate = self
        self.monthTableView.dataSource = self
        
        self.months = ["Jan",
                  "Feb",
                  "Mar",
                  "April",
                  "May",
                  "June",
                  "July",
                  "Aug",
                  "Sept",
                  "Oct",
                  "Nov",
                  "Dec"]
    }
    
    func getIADateRange(year: Int, month: Int) {
        let url = archiveAPI.dateRangeURL(year: year, month: month)
        
        archiveAPI.getIARequestItems(url: url) {
            (response: [ShowMetadata]?) -> Void in
            
            DispatchQueue.main.async{
                if let r = response {
                 //   self.showMetadatas = r
                  //  if let s = self.showMetadatas {
                  //      self.showMetadatas = s.sorted(by: { $0.date! < $1.date! })
                  //  }
                  //  self.showListTableView.reloadData()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.months.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = monthTableView.dequeueReusableCell(withIdentifier: "MonthCell", for: indexPath) as! MonthTableViewCell
        let month = self.months[indexPath.row]
        if let year = self.year {
            cell.monthLabel?.text = month + " " + String(year)
        }
        else {
            cell.monthLabel?.text = month
        }
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = monthTableView.indexPathForSelectedRow else { return }
        if let target = segue.destination as? ShowsListViewController {
            let m = indexPath.row + 1
            target.month = m
            if let y = self.year {
                target.year = y
            }
            target.resetMonth()
            target.player = player
        }
    }

}
