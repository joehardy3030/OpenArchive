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
    var yearTotals: [Int:Int?] = [:]
    
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
        getYearTotals()
    }
    
    func getYearTotal(year: Int, sbdOnly: Bool, reload: Bool) {
     //    func yearRangeTotalURL(year: Int, sbdOnly: Bool, collection: String = "GratefulDead") -> String {
        guard let selectedCollection = self.selectedCollection else { return }
        let url = archiveAPI.yearRangeTotalURL(year: year, sbdOnly: sbdOnly, collection: selectedCollection)
        print(url)
        archiveAPI.getIARequestTotal(url: url) { (response: YearsTotalResponse?) -> Void in
            DispatchQueue.main.async {
                if let yearTotal = response?.totalCount {
                    print("Year total \(yearTotal)")
                    self.yearTotals[year] = yearTotal
                    print(self.yearTotals[year])
                    self.yearTableView.reloadData()
                    
                    //
                } else {
                    print("No data available.")
                }
            }
        }
    }
    
    func getYearTotals() {
        for (index, y) in self.years.enumerated() {
            let isLast = index == self.years.count - 1
            getYearTotal(year: y, sbdOnly: false, reload: isLast)
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.years.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = yearTableView.dequeueReusableCell(withIdentifier: "ArchiveCell", for: indexPath) as! ArchiveCell
        let year = self.years[indexPath.row]
        if let yearTotal = self.yearTotals[year] {
            if let y = yearTotal {
                cell.titleLabel?.text = String("\(year) (\(y) tapes)")
            }
            
        }
        else {
            cell.titleLabel?.text = String(year)
        }
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
    
