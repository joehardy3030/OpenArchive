//
//  CollectionViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 4/27/25.
//  Copyright © 2025 Carquinez. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class CollectionViewController: ArchiveSuperViewController, UITableViewDelegate, UITableViewDataSource {
    let collections = ["Grateful Dead", "BMFS"]
    var selectedCollection: String?
    
    @IBOutlet weak var tableView: UITableView! // Connect this in your storyboard

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }

    // MARK: - TableView DataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collections.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CollectionCell", for: indexPath)
        cell.textLabel?.text = collections[indexPath.row]
        print("got to here")
        print(cell)
        return cell
    }

    // MARK: - TableView Delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCollection = collections[indexPath.row]
      //  performSegue(withIdentifier: "CollectionToYearsSegue", sender: self)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CollectionToYearsSegue" {
            if let destinationVC = segue.destination as? YearViewController {
                destinationVC.selectedCollection = selectedCollection
                destinationVC.db = db
            }
        }
    }
}
