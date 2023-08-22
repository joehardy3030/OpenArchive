//
//  MonthViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/2/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit

class MonthViewController: ArchiveSuperViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var sbdToggle: UISegmentedControl!
    @IBOutlet weak var monthTableView: UITableView!
    var months: [String] = []
    var monthCount: [Int:Int] = [:]
    var year: Int?
    var sbdOnly = true // look at observer pattern
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.monthTableView.delegate = self
        self.monthTableView.dataSource = self
        sbdToggle.selectedSegmentIndex = getSbdToggle()
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
    
    override func viewWillAppear(_ animated: Bool) {
        setSbdToggle()
        getShows()
    }
    
    @IBAction func sbdToggle(_ sender: Any) {
        if sbdToggle.selectedSegmentIndex == 0 {
            sbdOnly = false
        }
        else {
            sbdOnly = true
        }
        getShows()
    }
    
    func getSbdToggle() -> Int {
        var sbdInt = 1
        switch sbdOnly {
        case false:
            sbdInt = 0
        default:
            sbdInt = 1
        }
        return sbdInt
    }
    
    func setSbdToggle() {
        switch sbdOnly {
        case false:
            sbdToggle.selectedSegmentIndex = 0
        default:
            sbdToggle.selectedSegmentIndex = 1
        }

    }

    
    func getShows() {
        if let y = year {
            for i in 1...12 {
                getIADateRange(year: y, month: i, sbdOnly: sbdOnly)
            }
        }
    }
    
    func getIADateRange(year: Int, month: Int, sbdOnly: Bool) {
        let url = archiveAPI.dateRangeURL(year: year, month: month, sbdOnly: sbdOnly)
        
        archiveAPI.getIARequestItems(url: url) {
            (response: [ShowMetadata]?) -> Void in
            
            DispatchQueue.main.async{
                if let r = response {
                    var smd: [ShowMetadata]?
                    smd = r
                    let count = smd?.count
                    self.monthCount[month] = count
                    self.monthTableView.reloadData()
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
       // var countString: String?
        let cell = monthTableView.dequeueReusableCell(withIdentifier: "MonthCell", for: indexPath) as! MonthTableViewCell
        let month = self.months[indexPath.row]
        let count = self.monthCount[indexPath.row + 1]
        //print(count)
        if let year = self.year {
            if let c = count, c > 0 {
                cell.monthLabel?.text = month + " " + String(year) + " " + "(" + String(c) + " tapes)"
            }
            else {
                cell.monthLabel?.text = month + " " + String(year)
            }
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
            if sbdToggle.selectedSegmentIndex == 0 {
                target.sbdOnly = false
            }
            else {
                target.sbdOnly = true
            }
            target.resetMonth()
            target.db = db
        }
    }

}
