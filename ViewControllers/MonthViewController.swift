//
//  MonthViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/2/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit

class MonthViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var monthTableView: UITableView!
    var months: [String] = []
    var year: Int?
    let utils = Utils()
    
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
        utils.getMemory()
        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.months.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = monthTableView.dequeueReusableCell(withIdentifier: "MonthCell", for: indexPath) as! MonthTableViewCell
        let month = self.months[indexPath.row]
        cell.monthLabel?.text = month
        if let year = self.year {
            cell.monthLabel?.text = month + " " + String(year)
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
        }
    }

}
