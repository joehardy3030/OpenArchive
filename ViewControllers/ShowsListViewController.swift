//
//  ShowsListViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/4/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import SwiftyJSON

@available(iOS 13.0, *)
class ShowsListViewController: ArchiveSuperViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var sbdToggle: UISegmentedControl!
    @IBOutlet weak var showListTableView: UITableView!
    var year: Int?
    var month: Int?
    //var startYear: String?
    //var endYear: String?
    //var searchTerm: String?
    //var minRating: String?
    var identifiers: [String]?
    var showMetadatas: [ShowMetadata]?
    var sbdOnly = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showListTableView.delegate = self
        self.showListTableView.dataSource = self
        self.showListTableView.rowHeight = 135.0
        sbdToggle.selectedSegmentIndex = getSbdToggle()
    }
    
    /*
    func getIADateRange() {
        guard let year = self.year, let month = self.month else { return }
        let url = archiveAPI.dateRangeURL(year: year, month: month, sbdOnly: sbdOnly)

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
     */
    
    
    func getIASearchTerm(searchTermsModel: SearchTermsModel) {

        let url = archiveAPI.searchTermURL(searchTerm: searchTermsModel.searchTerm ?? "",
                                           venue: searchTermsModel.venue,
                                           minRating: searchTermsModel.minRating,
                                           startYear: searchTermsModel.startYear,
                                           endYear: searchTermsModel.endYear)
        archiveAPI.getIARequestItemsDecodable(url: url) {
            (response: ShowMetadatas?) -> Void in
             DispatchQueue.main.async{
                if let r = response {
                    self.showMetadatas = r.items?.sorted(by: { $0.date! < $1.date! })
                    // print(r)
                    self.showListTableView.reloadData()
                }
            }
        }
    }
    
    
    func getIADateRange() {
        guard let year = self.year, let month = self.month else { return }
        let url = archiveAPI.dateRangeURL(year: year, month: month, sbdOnly: sbdOnly)

        archiveAPI.getIARequestItemsDecodable(url: url) {
            (response: ShowMetadatas?) -> Void in
            
             DispatchQueue.main.async{
                if let r = response {
                    //self.showMetadatas = r.items
                    //if let s = self.showMetadatas {
                    self.showMetadatas = r.items?.sorted(by: { $0.date! < $1.date! })
                    //}
                    self.showListTableView.reloadData()
                }
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
            if let v = showMDs[indexPath.row].venue, let c = showMDs[indexPath.row].coverage {
                cell.venueLabel.text = v + ", " + c
            }
            else {
                cell.venueLabel.text = showMDs[indexPath.row].venue
            }
            cell.transfererLabel.text = showMDs[indexPath.row].transferer
            cell.sourceLabel.text = showMDs[indexPath.row].source
            if let s = showMDs[indexPath.row].avg_rating {
                var starRating = String(s)
                starRating = starRating + " stars " + String(showMDs[indexPath.row].num_reviews!) + " ratings"
                cell.starsLabel.text = starRating
            }
            else {
                cell.starsLabel.text = ""
            }
        }
        else {
            cell.venueLabel.text = "No show"
        }
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = showListTableView.indexPathForSelectedRow else { return }
        if let target = segue.destination as? ShowViewController, let showMDs = self.showMetadatas {
            target.showMetadata = showMDs[indexPath.row]
            //target.identifier = showMDs[indexPath.row].identifier
            //target.showDate = showMDs[indexPath.row].date
            target.showType = .archive
            target.db = db
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
