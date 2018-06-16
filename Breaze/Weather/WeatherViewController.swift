//
//  FirstViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 1/31/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit
import CoreLocation

class WeatherViewController: UITableViewController, CLLocationManagerDelegate  {
    
    @IBOutlet var locationLabel: UILabel!
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation!
    // https://www.hackingwithswift.com/read/22/2/requesting-location-core-location
    var utils = Utils()
    var store = WeatherStore()
    var simpleForecastArray = [SimpleForecastDay]()

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        locationManager.requestLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("error")
    }
    
    func locationManager(_ manager: CLLocationManager,
                                  didUpdateLocations locations: [CLLocation]){
        
        self.currentLocation = locations.last
        //eventDate = location.timestamp
       // locationText = String(self.currentLocation.coordinate.latitude) + ", " + String(self.currentLocation.coordinate.longitude)
        
        DispatchQueue.main.async{
           // self.locationLabel.text = locationText
            let parameters = [
                "latitude": String(self.currentLocation.coordinate.latitude),
                "longitude": String(self.currentLocation.coordinate.longitude)
            ]
            self.updateSimpleForecastData(paramaters: parameters)
        }
        
    }
    
    func updateSimpleForecastData(paramaters: [String:String]?) {
        // Grab the HourlyForecast data and put it in the HourlyForecastData
        //store.fetchSimpleForecast
       // var locationText: String!
       // locationText = String(self.currentLocation.coordinate.latitude) + ", " + String(self.currentLocation.coordinate.longitude)
        store.fetchLocalSimpleForecast(parameters: paramaters){
            (SimpleForecastResult) -> Void in
            switch SimpleForecastResult {
            case let .success(simpleForecast, displayCity):
                self.simpleForecastArray = simpleForecast
                print("count simple \(self.simpleForecastArray.count)")
                DispatchQueue.main.async{
                    self.tableView.reloadData()
                    self.locationLabel.text = displayCity
                }
            case let .failure(error):
                print("Error fetching simple forecast: \(error)")
                
            }
            
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.simpleForecastArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Get a new or recycled cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "SimpleForecastCell", for: indexPath) as! WeatherCell
        
        // Set the text on the cell with the description of the item
        // that s the nth index of items, where n = row this cell
        // will appear in the tableview
        let weatherCellData = self.simpleForecastArray[indexPath.row]
        
        cell.highTempLabel?.text = weatherCellData.high + " F"
        cell.lowTempLabel?.text = weatherCellData.low + " F"
        cell.dayLabel?.text = weatherCellData.weekday_short
        
        cell.iconLabel?.text = utils.switchConditionsText(icon: weatherCellData.icon)
        cell.iconImage?.image = utils.switchConditionsImage(icon: weatherCellData.icon)
        return cell
    }

}

