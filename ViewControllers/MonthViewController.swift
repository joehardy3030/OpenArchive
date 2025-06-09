//
//  MonthViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/2/20.
//  Copyright 2020 Carquinez. All rights reserved.
//

import UIKit

class MonthViewController: ArchiveSuperViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var sbdToggle: UISegmentedControl!
    @IBOutlet weak var monthTableView: UITableView!
    var months: [String] = []
    var monthCount: [String:Int] = [:]
    var year: Int?
    var sbdOnly = true // look at observer pattern
    var selectedCollection: String = "GratefulDead"
    var allShowsForYear: [ShowMetadata]? // To store all shows fetched for the year
    var monthsWithCounts: [(month: String, countText: String)] = []
    var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.monthTableView.delegate = self
        self.monthTableView.dataSource = self

        // Setup activity indicator
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)

        if selectedCollection == "GratefulDead" {
            sbdOnly = true // look at observer pattern
        }
        else {
            sbdOnly = false
        }
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
    
    func getIADateRangeYear(year: Int, sbdOnly: Bool) {
        let url = archiveAPI.dateRangeYearURL(year: year, sbdOnly: sbdOnly, collection: selectedCollection)
        print(url)
        activityIndicator.startAnimating()
        monthTableView.isHidden = true

        archiveAPI.getIARequestItemsDecodable(url: url) { (response: ShowMetadatas?, error: Error?) -> Void in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.monthTableView.isHidden = false

                if let error = error {
                    self.showErrorAlert(title: "Error", message: "Failed to fetch shows: \(error.localizedDescription)")
                    self.allShowsForYear = nil
                    self.monthCount = [:]
                    self.updateMonthsWithCounts()
                    self.monthTableView.reloadData()
                    return
                }

                if let showMetadatas = response?.items, !showMetadatas.isEmpty {
                    self.allShowsForYear = showMetadatas
                    self.monthCount = [:]
                    
                    let groupedByMonth = Dictionary(grouping: showMetadatas, by: { $0.month })
                    for (apiMonthKey, showsInMonth) in groupedByMonth {
                        if let unwrappedApiKey = apiMonthKey {
                            if let monthNameForDisplay = self.monthName(from: unwrappedApiKey) {
                                self.monthCount[monthNameForDisplay] = showsInMonth.count
                            }
                        }
                    }
                    
                    self.updateMonthsWithCounts()
                    self.monthTableView.reloadData()
                } else {
                    self.showErrorAlert(title: "No Shows", message: "No shows found for the selected year and criteria.")
                    self.allShowsForYear = nil
                    self.monthCount = [:]
                    self.updateMonthsWithCounts()
                    self.monthTableView.reloadData()
                }
            }
        }
    }
    
    func showErrorAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func updateMonthsWithCounts() {
        self.monthsWithCounts = self.months.map { monthName -> (month: String, countText: String) in
            let count = self.monthCount[monthName] ?? 0
            return (month: monthName, countText: "\(count) shows")
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.monthsWithCounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = monthTableView.dequeueReusableCell(withIdentifier: "MonthCell", for: indexPath) as! MonthTableViewCell
        let monthData = self.monthsWithCounts[indexPath.row]
        if let year = self.year {
            let countString = monthData.countText.components(separatedBy: " ").first ?? "0"
            if let count = Int(countString), count > 0 {
                cell.monthLabel?.text = "\(monthData.month) \(String(year)) (\(count) tapes)"
            } else {
                cell.monthLabel?.text = "\(monthData.month) \(String(year))"
            }
        } else {
            cell.monthLabel?.text = monthData.month
        }

        cell.monthLabel?.applyTextStyle(AppFonts.bodyPrimary)
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = monthTableView.indexPathForSelectedRow else { return }
        if let target = segue.destination as? ShowsListViewController {
            let selectedMonthInt = indexPath.row + 1
            target.month = selectedMonthInt
            if let y = self.year {
                target.year = y
            }
            if sbdToggle.selectedSegmentIndex == 0 {
                target.sbdOnly = false
            }
            else {
                target.sbdOnly = true
            }
            target.selectedCollection = selectedCollection
            
            if let allShows = self.allShowsForYear {
                let showsForSelectedMonth = allShows.filter { show -> Bool in
                    guard let showMonthString = show.month?.split(separator: "-").last,
                          let showMonthInt = Int(showMonthString) else {
                        return false
                    }
                    return showMonthInt == selectedMonthInt
                }
                target.showsForMonth = showsForSelectedMonth
            }
        }
    }
    
    func monthName(from monthString: String) -> String? {
        // Helper to get full month name from "YYYY-MM" string
        let components = monthString.split(separator: "-")
        if let monthString = components.last, let monthIndex = Int(monthString) {
            let monthName = self.months[monthIndex - 1]
            return monthName
        }
        return nil
    }
}
