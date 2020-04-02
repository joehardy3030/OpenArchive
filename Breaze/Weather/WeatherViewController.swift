//
//  FirstViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 1/31/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class WeatherViewController: UITableViewController { //, CLLocationManagerDelegate  {
    
    @IBOutlet var locationLabel: UILabel!
    //let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var currentLocation: CLLocation!
    let locationManager = CLLocationManager()
    let refresher = UIRefreshControl()
    var utils = Utils()
    var openWeather = OpenWeatherAPI()
    var weatherArray = [WeatherModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.addSubview(self.refresher)
        self.refresher.addTarget(self, action: #selector(self.handleRefresh(_:)), for: UIControl.Event.valueChanged)
        self.refresher.tintColor = UIColor.gray
        self.locationManager.delegate = self
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            self.locationManager.startUpdatingLocation()
        }
        else {
            self.updateOpenWeatherCurrent()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func updateOpenWeatherCurrent(location: CLLocation) {
         let parameters = [
             "latitude": String(Double(location.coordinate.latitude)),
             "longitude": String(Double(location.coordinate.longitude)),
         ]
        print(parameters)
         buildURLUpdateWeather(parameters: parameters)
     }

     func updateOpenWeatherCurrent() {
         var parameters: [String:String]?
         guard let location = LocationsStorage.shared.locations.last else { return }
         parameters = [
             "latitude": String(location.latitude),
             "longitude": String(location.longitude)
         ]
         buildURLUpdateWeather(parameters: parameters)
     }
    
    func buildURLUpdateWeather(parameters: [String:String]?) {
        
        let url = openWeather.buildURL(queryType: .current, parameters: parameters)
        openWeather.getCurrent(url: url) {
            (weatherModel: WeatherModel?, city: String?) -> Void in
            if let wm = weatherModel, let c = city {
                if self.weatherArray.isEmpty {
                    self.weatherArray.append(wm)
                }
                else {
                    self.weatherArray[0] = wm
                }
                DispatchQueue.main.async{
                    self.tableView.reloadData()
                    self.locationLabel.text = c
                }
            }
        }
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.weatherArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Get a new or recycled cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "SimpleForecastCell", for: indexPath) as! WeatherCell
        
        // Set the text on the cell with the description of the item
        // that s the nth index of items, where n = row this cell
        // will appear in the tableview
        let index = indexPath.row
        let weatherCellData = self.weatherArray[index]
        print(weatherCellData)

        if let humidity = weatherCellData.avehumidity {
            cell.humidityLabel?.text = String(format:"%.1f", humidity) + " %"
        }

        if let temp = weatherCellData.temp {
            cell.currentTempLabel?.text = String(format:"%.1f", temp) + " F"
        }
        cell.dayLabel?.text = utils.getDayOfWeek()
        
        if let description = weatherCellData.main_description {
            cell.iconLabel?.text = description
            cell.iconImage?.image = utils.switchConditionsImage(icon: description.lowercased())
        }
        
        return cell
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        // Do some reloading of data and update the table view's data source
        // Fetch more objects from a web service, for example...
        
        self.updateOpenWeatherCurrent()
        refreshControl.endRefreshing()
    }
    
}

extension WeatherViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
        guard let locValue: CLLocation = manager.location else { return }
        print(locValue)
        updateOpenWeatherCurrent(location: locValue)
    }
    
    func locationManager(_ manager: CLLocationManager,
                                  didFailWithError error: Error) {
        self.locationManager.stopUpdatingLocation()
        print("Hourly View controller location error")
        updateOpenWeatherCurrent()
    }
    
}

