//
//  DownloadsViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/17/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit

class DownloadsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var showListTableView: UITableView!
    let network = NetworkUtility()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showListTableView.delegate = self
        self.showListTableView.dataSource = self
        self.showListTableView.rowHeight = 135.0
        self.getDownloadedShows()
    }
    
    func getDownloadedShows() {
        DispatchQueue.main.async{
            let shows = self.network.getAllDownloadDocs()
            print(shows)
        }

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return ShowsListTableViewCell()
    }
    

}
