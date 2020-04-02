//
//  SecondViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 1/31/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class SmogViewController: UITableViewController {

    var locationManager = CLLocationManager()
    //var currentLocation: CLLocation!
    var refresher: UIRefreshControl!
    var store = SmogStore()
    var smogArray = [SmogDay]()
    var utils = Utils()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refresher = UIRefreshControl()
        self.tableView.addSubview(self.refresher)
        refresher.addTarget(self, action: #selector(self.handleRefresh(_:)), for: UIControl.Event.valueChanged)
        refresher.tintColor = UIColor.gray
        self.updateSmogForecast()
    }
    
    func updateSmogForecast() {
        var parameters: [String:String]?
        guard let location = LocationsStorage.shared.locations.last else { return }
        parameters = [
            "latitude": String(location.latitude),
            "longitude": String(location.longitude)
        ]
        
        store.fetchSmogForecast(location: parameters)
         {
             (SmogForecastResult) -> Void in
             
             switch SmogForecastResult {
             case let .success(smogForecast):
                 self.smogArray = smogForecast
                 DispatchQueue.main.async{
                     self.tableView.reloadData()
                 }
             case let .failure(error):
                 print("Error fetching simple forecast: \(error)")
             }
         }
    }
    
    func updateSmogForecast(location: CLLocation) {
        var parameters: [String:String]?
        parameters = [
            "latitude": String(location.coordinate.latitude),
            "longitude": String(location.coordinate.longitude)
        ]
        
        store.fetchSmogForecast(location: parameters)
        {
            (SmogForecastResult) -> Void in
            
            switch SmogForecastResult {
            case let .success(smogForecast):
                self.smogArray = smogForecast
                DispatchQueue.main.async{
                    self.tableView.reloadData()
                }
            case let .failure(error):
                print("Error fetching simple forecast: \(error)")
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.smogArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // create an instance of UITableViewCell
       //  let cell = UITableViewCell(style: .value1, reuseIdentifier: "UITableViewCell")
        
        // Get a new or recycled cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "SmogForecastCell", for: indexPath) as! SmogCell
        
        // Set the text on the cell with the description of the item
        // that s the nth index of items, where n = row this cell
        // will appear in the tableview
        let smogReading = self.smogArray[indexPath.row]
        
        if let siteName = smogReading.siteName {
            cell.siteNameLabel?.text = siteName
        }
        else {
            cell.siteNameLabel?.text = "n/a"
            cell.siteNameLabel?.textColor = .gray
        }

        if let pm25 = smogReading.PM25 {
            cell.PM25Label?.text = String(pm25)
            cell.PM25Label?.textColor = getTextColor(AQI: pm25)
        }
        else {
            cell.PM25Label?.text = "n/a"
            cell.PM25Label?.textColor = .gray
        }

        if let ozone = smogReading.ozone {
            cell.ozoneLabel?.text = String(ozone)
            cell.ozoneLabel?.textColor = getTextColor(AQI: ozone)
        }
        else {
            cell.ozoneLabel?.text = "n/a"
            cell.ozoneLabel?.textColor = .gray
        }
 
        if let NO2 = smogReading.NO2 {
            cell.NO2Label?.text = String(NO2)
            cell.NO2Label?.textColor = getTextColor(AQI: NO2)
        }
        else {
            cell.NO2Label?.text = "n/a"
            cell.NO2Label?.textColor = .gray
        }

        return cell
    }
    
    private func getTextColor(AQI: Int) -> UIColor {
        let textColor: UIColor
        let goodColor = UIColor.init(red: 0.184, green: 0.5, blue: 0.188, alpha: 1)
        let moderateColor = UIColor.init(red: 0.8, green: 0.4, blue: 0.0, alpha: 1)

        switch AQI {
        case 0...49:
            textColor = goodColor
        case 50...99:
            textColor = moderateColor
        case 100...149:
            textColor = UIColor.orange
        case 150...1000:
            textColor = UIColor.red
        default:
            textColor = UIColor.black
        }
        return textColor
    }

    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        // Do some reloading of data and update the table view's data source
        // Fetch more objects from a web service, for example...
        self.updateSmogForecast()
        refreshControl.endRefreshing()
    }

}

extension SmogViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("location error")
        self.locationManager.stopUpdatingLocation()
        if let location = LocationsStorage.shared.locations.last {
            self.updateSmogForecast(location: location.clLocation)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
        if let location: CLLocation = manager.location {
            self.updateSmogForecast(location: location)
        }
    }
}
