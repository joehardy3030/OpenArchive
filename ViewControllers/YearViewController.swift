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
        // TODO: Consider adding an activity indicator

        switch selectedCollection {
        case "GratefulDead":
            self.years += 1965...1995
        case "BillyStrings":
            self.years += 2015...2025 // Assuming current year, adjust if needed
        case "PhilLeshandFriends":
            self.years += 1996...2025 // Assuming current year, adjust if needed
        case "GooseBand":
            self.years += 2015...2025 // Assuming current year, adjust if needed
        case "Furthur":
            self.years += 1996...2015
        case "TheOtherOnes":
            self.years += 1996...2015
        case "DeadAndCompany":
            self.years += 2015...2025 // Assuming current year, adjust if needed
        case "Radiators":
            self.years += 1983...2025 // Assuming current year, adjust if needed
        case "Phish":
            self.years += 1983...2025 // Assuming current year, adjust if needed
        default:
            self.years += 1965...1995 // Default fallback
        }
        
        if !self.years.isEmpty {
            // For now, sbdOnly is hardcoded to false. 
            // You might want to connect this to a UI switch or another setting.
            fetchAllShowCounts(forYears: self.years, sbdOnly: false)
        } else {
            // Handle the case where no years are determined (e.g., show empty state)
            self.yearTableView.reloadData()
        }
    }

    // MARK: - Data Fetching

    private func fetchShowCountForYear(_ year: Int, sbdOnly: Bool, collection: String, completion: @escaping (_ year: Int, _ count: Int?) -> Void) {
        let url = archiveAPI.dateRangeYearURL(year: year, sbdOnly: sbdOnly, collection: collection)
        // print("Fetching count for year \(year) with URL: \(url)") // For debugging

        archiveAPI.getIARequestItemsDecodable(url: url) { (response: ShowMetadatas?) -> Void in
            if let showMetadatas = response?.items {
                completion(year, showMetadatas.count)
            } else {
                // print("No show data available for year \(year).")
                completion(year, nil) // Pass nil or 0 to indicate no data or an error
            }
        }
    }

    func fetchAllShowCounts(forYears years: [Int], sbdOnly: Bool) {
        guard let selectedCollection = self.selectedCollection else {
            print("Error: selectedCollection is nil. Cannot fetch show counts.")
            // Clear existing data and update UI if necessary
            self.yearCount.removeAll()
            self.yearTableView.reloadData()
            // Optionally, inform the user via an alert
            return
        }

        print("Starting to fetch show counts for \(years.count) years concurrently.")
        // self.activityIndicator.startAnimating() // Example: If you have a loading indicator

        let group = DispatchGroup()
        var temporaryYearCounts = [Int: Int]() // Collect results here

        for year in years {
            group.enter() // Increment the group's counter
            fetchShowCountForYear(year, sbdOnly: sbdOnly, collection: selectedCollection) { (fetchedYear, count) in
                temporaryYearCounts[fetchedYear] = count ?? 0 // Store the count, default to 0 if nil
                // print("Fetched count for year \(fetchedYear): \(count ?? 0)")
                group.leave() // Decrement the group's counter
            }
        }

        // This block is executed once all tasks in the group have called group.leave()
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            print("All show count fetches completed.")
            // self.activityIndicator.stopAnimating() // Example: Stop loading indicator

            // Now update the main data source and reload the table view ONCE
            self.yearCount = temporaryYearCounts
            self.yearTableView.reloadData()
            print("YearTableView reloaded with all counts.")
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.years.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = yearTableView.dequeueReusableCell(withIdentifier: "ArchiveCell", for: indexPath) as! ArchiveCell
        let year = self.years[indexPath.row]
        if let count = self.yearCount[year] {
            cell.titleLabel?.text = "\(year) (\(count) tapes)"
        }
        else {
            cell.titleLabel?.text = "\(year)"
        }
        //let count = self.yearCount[year] ?? 0 // Default to 0 if count not yet available or nil
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
    
