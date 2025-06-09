//
//  ShowsListViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/4/20.
//  Copyright 2020 Carquinez. All rights reserved.
//

import UIKit
import SwiftyJSON

@available(iOS 13.0, *)
class ShowsListViewController: ArchiveSuperViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var sbdToggle: UISegmentedControl!
    @IBOutlet weak var showListTableView: UITableView!
    var year: Int?
    var month: Int?
    var identifiers: [String]?
    var showMetadatas: [ShowMetadata]?
    var sbdOnly = true
    var selectedCollection: String = "GratefulDead"
    var showsForMonth: [ShowMetadata]? // To receive data from MonthViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showListTableView.delegate = self
        self.showListTableView.dataSource = self
        self.showListTableView.rowHeight = UITableView.automaticDimension
        self.showListTableView.estimatedRowHeight = 165.0
        self.showListTableView.register(ShowsListTableViewCell.self, forCellReuseIdentifier: "ShowListCell")
        sbdToggle.selectedSegmentIndex = getSbdToggle()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetMonth() // Load data when the view is about to appear
    }
    
    func getIASearchTerm(searchTermsModel: SearchTermsModel) {
        let url = archiveAPI.searchTermURL(searchTerm: searchTermsModel.searchTerm ?? "",
                                           venue: searchTermsModel.venue,
                                           minRating: searchTermsModel.minRating,
                                           startYear: searchTermsModel.startYear,
                                           endYear: searchTermsModel.endYear,
                                           sbdOnly: searchTermsModel.sbdOnly,
                                           collection: searchTermsModel.collection)
        archiveAPI.getIARequestItemsDecodable(url: url) {
            (response: ShowMetadatas?, error: Error?) -> Void in
             DispatchQueue.main.async{
                if let error = error {
                    // Basic error handling: print and clear data
                    print("Error fetching search results: \(error.localizedDescription)")
                    self.showMetadatas = nil
                    self.showListTableView.reloadData()
                    // TODO: Implement user-facing error alert
                    return
                }

                if let r = response, let items = r.items, !items.isEmpty {
                    self.showMetadatas = items.sorted(by: { $0.date! < $1.date! })
                } else {
                    // No error, but no items or nil response
                    self.showMetadatas = nil
                    // TODO: Optionally inform user that no results were found
                }
                self.showListTableView.reloadData()
            }
        }
    }
    
    
    func getIADateRange() {
        guard let year = self.year, let month = self.month else { return }
        let url = archiveAPI.dateRangeURL(year: year, month: month, sbdOnly: sbdOnly, collection: selectedCollection)

        archiveAPI.getIARequestItemsDecodable(url: url) {
            (response: ShowMetadatas?, error: Error?) -> Void in
            
             DispatchQueue.main.async{
                if let error = error {
                    // Basic error handling: print and clear data
                    print("Error fetching date range results: \(error.localizedDescription)")
                    self.showMetadatas = nil
                    self.showListTableView.reloadData()
                    // TODO: Implement user-facing error alert
                    return
                }

                if let r = response, let items = r.items, !items.isEmpty {
                    self.showMetadatas = items.sorted(by: { $0.date! < $1.date! })
                } else {
                    // No error, but no items or nil response
                    self.showMetadatas = nil
                    // TODO: Optionally inform user that no results were found
                }
                self.showListTableView.reloadData()
            }
        }
    }

    @IBAction func sbdToggle(_ sender: Any) {
        if sbdToggle.selectedSegmentIndex == 0 {
            sbdOnly = false
        }
        else {
            sbdOnly = true
        }
        resetMonth()
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
     

    func resetMonth() {
        // If showsForMonth is available, use it directly
        if let providedShows = showsForMonth, !providedShows.isEmpty {
            self.showMetadatas = providedShows.sorted(by: { $0.date! < $1.date! })
            self.showListTableView.reloadData()
        }
        // Otherwise, fetch from API
        else {
            self.getIADateRange()
        }
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
            cell.configure(with: showMDs[indexPath.row])
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let showMDs = self.showMetadatas {
            let show = showMDs[indexPath.row]
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let showVC = storyboard.instantiateViewController(withIdentifier: "ShowViewController") as? ShowViewController {
                showVC.showMetadata = show
                showVC.showType = .archive
                navigationController?.pushViewController(showVC, animated: true)
            }
        }
    }
    
    override func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let target = viewController as? MonthViewController {
            if target.sbdOnly != sbdOnly {
                target.sbdOnly = sbdOnly
                target.setSbdToggle()
                target.getShows()
            }
        }
    }
    
    
}
