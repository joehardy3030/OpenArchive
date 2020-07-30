//
//  ArchiveViewController.swift
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
   // let utils = Utils()
    var archiveAPI = ArchiveAPI()
    var years: [Int] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.yearTableView.delegate = self
        self.yearTableView.dataSource = self
        self.years += 1965...1995
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.years.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = yearTableView.dequeueReusableCell(withIdentifier: "ArchiveCell", for: indexPath) as! ArchiveCell
        let year = self.years[indexPath.row]
        cell.titleLabel?.text = String(year)
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = yearTableView.indexPathForSelectedRow else { return }
        if let target = segue.destination as? MonthViewController {
            let year = self.years[indexPath.row]
            target.year = year
            target.player = player
            print(player as Any)
        }
    }
}
    
