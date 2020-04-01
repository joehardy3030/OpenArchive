//
//  PlacesTableViewController.swift
//  Breaze
//
//  Created by Joe Hardy on 4/1/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import UserNotifications

class PlacesTableViewController: UITableViewController {
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return LocationsStorage.shared.locations.count
  }
  /*
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceCell", for: indexPath)
    return cell
  }
  */
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 110
  }
    
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceCell", for: indexPath)
    let location = LocationsStorage.shared.locations[indexPath.row]
    cell.textLabel?.numberOfLines = 3
    cell.textLabel?.text = location.description
    cell.detailTextLabel?.text = location.dateString
    return cell
  }
}
