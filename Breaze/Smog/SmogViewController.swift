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

    var locationManager: CLLocationManager!
    var currentLocation: CLLocation!
    var refresher: UIRefreshControl!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var store = SmogStore()
    var smogArray = [SmogDay]()
    var utils = Utils()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Pull the smog forecast data when loading the tab
        // and display it asychronously when the data arrives
        var lastLoc = utils.fetchLastLocation()
        print(lastLoc)
        
        var location = [
            "latitude": "37.785834",
            "longitude": "-122.406417"
        ]
        if (lastLoc.latitude != nil) {
            location = [
                "latitude": lastLoc.latitude!,
                "longitude": lastLoc.longitude!
            ]
        }
        else {
            print("lastLoc is nil")
        }
//        NotificationCenter.default.addObserver(self, selector: #selector(receivedLocationNotification(notification:)), name: .alocation, object: nil)

        store.fetchSmogForecast(location: location)
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
        // Do any additional setup after loading the view, typically from a nib.
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
        
        cell.siteNameLabel?.text = smogReading.siteName

        cell.PM25Label?.text = String(smogReading.PM25)
        cell.PM25Label?.textColor = getTextColor(AQI: smogReading.PM25)
        
        cell.ozoneLabel?.text = String(smogReading.ozone)
        cell.ozoneLabel?.textColor = getTextColor(AQI: smogReading.ozone)
 //       cell.SO2Label?.text = String(smogReading.SO2)
        
        cell.NO2Label?.text = String(smogReading.NO2)
        cell.NO2Label?.textColor = getTextColor(AQI: smogReading.NO2)

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


}

