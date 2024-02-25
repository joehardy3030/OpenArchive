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
    var monthCount: [String:Int] = [:]
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
            print("year \(String(describing: year))")
            getIADateRangeYear(year: y, sbdOnly: sbdOnly)
        }
    }
    
    
    /*
    archiveAPI.getIARequestItemsDecodable(url: url) {
        (response: ShowMetadatas?) -> Void in
        
         DispatchQueue.main.async{
            if let r = response {
                self.showMetadatas = r.items
                if let s = self.showMetadatas {
                    self.showMetadatas = s.sorted(by: { $0.date! < $1.date! })
                }
                self.showListTableView.reloadData()
            }
        }
    }
    */
    
    func getIADateRangeYear(year: Int, sbdOnly: Bool) {
        let url = archiveAPI.dateRangeYearURL(year: year, sbdOnly: sbdOnly)

        archiveAPI.getIARequestItemsDecodable(url: url) { (response: ShowMetadatas?) -> Void in
            DispatchQueue.main.async {
                if let showMetadatas = response?.items {
                    // Reset the monthCount dictionary for new data
                    self.monthCount = [:]

                    // Grouping by month
                    let groupedByMonth = Dictionary(grouping: showMetadatas, by: { $0.month })

                    // Counting and storing in monthCount
                    for (month, shows) in groupedByMonth {
                        if let month = month { // Ensure month is not nil
                            self.monthCount[month] = shows.count
                        }
                    }

                    // Optionally, print the results
                    for (month, count) in self.monthCount.sorted(by: { $0.key < $1.key }) {
                        print("Month: \(month), Count: \(count)")
                    }
                    self.monthTableView.reloadData()
                } else {
                    print("No data available.")
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
        print(self.months[indexPath.row])
        
        var monthArray = Array(repeating: 0, count: 12) // Array to hold counts for each month
        
        for (monthKey, monthCount) in monthCount {
            let components = monthKey.split(separator: "-")
            if let monthString = components.last, let monthIndex = Int(monthString) {
                let arrayIndex = monthIndex - 1 // Convert to zero-based index
                if arrayIndex >= 0 && arrayIndex < monthArray.count {
                    monthArray[arrayIndex] = monthCount
                }
            }
        }

        if let year = self.year {
            let c = monthArray[indexPath.row] 
            if c > 0 {
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
