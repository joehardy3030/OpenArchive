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
    var selectedCollection: String?
    
    @IBOutlet weak var tableView: UITableView! // Connect this in your storyboard

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }

    // MARK: - TableView DataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CollectionConfig.collectionsText.count - 1  // Exclude the last item
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CollectionCell", for: indexPath)
        cell.textLabel?.text = CollectionConfig.collectionsText[indexPath.row]
        return cell
    }
    

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CollectionToYearsSegue" {
            guard let indexPath = tableView.indexPathForSelectedRow else { return }
            print(indexPath)
            if let destinationVC = segue.destination as? YearViewController {
                destinationVC.selectedCollection = CollectionConfig.collections[indexPath.row]
                print(indexPath.row)
                print(destinationVC.selectedCollection as Any)
            }
        }
    }
}
