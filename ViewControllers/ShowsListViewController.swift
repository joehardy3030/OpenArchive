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
    var identifiers: [String]?
    var showMetadatas: [ShowMetadata]?
    var sbdOnly = true
    var selectedCollection: String = "GratefulDead"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showListTableView.delegate = self
        self.showListTableView.dataSource = self
        self.showListTableView.rowHeight = UITableView.automaticDimension
        self.showListTableView.estimatedRowHeight = 165.0
        self.showListTableView.register(ShowsListTableViewCell.self, forCellReuseIdentifier: "ShowListCell")
        sbdToggle.selectedSegmentIndex = getSbdToggle()
    }
    
    
    func getIASearchTerm(searchTermsModel: SearchTermsModel) {

        let url = archiveAPI.searchTermURL(searchTerm: searchTermsModel.searchTerm ?? "",
                                           venue: searchTermsModel.venue,
                                           minRating: searchTermsModel.minRating,
                                           startYear: searchTermsModel.startYear,
                                           endYear: searchTermsModel.endYear,
                                           collection: selectedCollection)
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
        let url = archiveAPI.dateRangeURL(year: year, month: month, sbdOnly: sbdOnly, collection: selectedCollection)

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
