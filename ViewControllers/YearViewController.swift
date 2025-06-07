//
//  YearViewController.swift
//  Breaze
//
//  Created by Joe Hardy on 6/24/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class YearViewController: ArchiveSuperViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var yearTableView: UITableView!
    var selectedCollection: String?
    var years: [Int] = []
    var yearCount: [Int:Int] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.yearTableView.delegate = self
        self.yearTableView.dataSource = self
        switch selectedCollection {
        case "GratefulDead":
            self.years += 1965...1995
        case "BillyStrings":
            self.years += 2015...2025
        case "PhilLeshandFriends":
            self.years += 1996...2025
        case "GooseBand":
            self.years += 2015...2025
        case "Furthur":
            self.years += 1996...2015
        case "TheOtherOnes":
            self.years += 1996...2015
        case "DeadAndCompany":
            self.years += 2015...2025
        case "Radiators":
            self.years += 1983...2025
        case "Phish":
            self.years += 1983...2025
        default:
            self.years += 1965...1995
        }
        getShows()
    }
    
    func getShows() {
        for y in self.years {
            getIADateRangeYear(year: y, sbdOnly: false)
        }
    }
    
    func getIADateRangeYear(year: Int, sbdOnly: Bool) {
        guard let selectedCollection = self.selectedCollection else { return }
        let url = archiveAPI.dateRangeYearURL(year: year, sbdOnly: sbdOnly, collection: selectedCollection)
        print(url)
        archiveAPI.getIARequestItemsDecodable(url: url) { (response: ShowMetadatas?) -> Void in
            DispatchQueue.main.async {
                if let showMetadatas = response?.items {
                    self.yearCount[year] = showMetadatas.count
                    print("\(year), \(String(describing: self.yearCount[year]))")
                    self.yearTableView.reloadData()
                } else {
                    print("No data available.")
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.years.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = yearTableView.dequeueReusableCell(withIdentifier: "ArchiveCell", for: indexPath) as! ArchiveCell
        let year = self.years[indexPath.row]
        cell.titleLabel?.text = String(year)
        cell.titleLabel?.applyTextStyle(AppFonts.bodyPrimary)
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = yearTableView.indexPathForSelectedRow else { return }
        if let target = segue.destination as? MonthViewController {
            let year = self.years[indexPath.row]
            target.year = year
            target.selectedCollection = selectedCollection ?? "GratefulDead"
        }
    }
}
    
