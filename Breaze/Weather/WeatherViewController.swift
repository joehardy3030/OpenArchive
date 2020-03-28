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
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation!
    var refresher: UIRefreshControl!
    var utils = Utils()
    var openWeather = OpenWeatherAPI()
    var weatherArray = [WeatherModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refresher = UIRefreshControl()
        tableView.addSubview(refresher)
        refresher.addTarget(self, action: #selector(self.handleRefresh(_:)), for: UIControl.Event.valueChanged)
        refresher.tintColor = UIColor.gray
        let location = utils.fetchLastLocation()
        if (location.latitude != nil) {
            let parameters = [
                "latitude": location.latitude!,
                "longitude": location.longitude!
            ]
            self.updateOpenWeatherCurrent(parameters: parameters)
        }
        else {
            self.updateOpenWeatherCurrent(parameters: nil)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(receivedLocationNotification(notification:)), name: .alocation, object: nil)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func receivedLocationNotification(notification: NSNotification){
        print("received notification")
        var parameters: [String:String]?
        self.currentLocation = appDelegate.currentLocation

        DispatchQueue.main.async{
            parameters = self.setParameters()
            self.updateOpenWeatherCurrent(parameters: parameters)
            print(self.currentLocation?.coordinate.latitude as Any)
            print(self.currentLocation?.coordinate.longitude as Any)
        }

    }

    func updateOpenWeatherCurrent(parameters: [String:String]?) {
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

        var parameters: [String:String]?
        parameters = setParameters()
        if (parameters != nil) {
            self.updateOpenWeatherCurrent(parameters: parameters)
            print("Location not nil")
        }
        else {
            self.updateOpenWeatherCurrent(parameters: nil)
            print("Location nil")
        }
    
        refreshControl.endRefreshing()
    }
    
    func setParameters() -> [String:String]? {
        // when currentLocation is nil, this barfs
        var parameters: [String:String]?
        if (self.currentLocation?.coordinate.latitude) != nil {
            parameters = [
                "latitude": String(self.currentLocation.coordinate.latitude),
                "longitude": String(self.currentLocation.coordinate.longitude)
            ]
        }
        return parameters
    }
    
}

