//
//  HourlyViewController.swift
//  Breaze
//
//  Created by Joe Hardy on 5/8/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class HourlyViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    
    var utils = Utils()
    var openWeather = OpenWeatherAPI()
    var weatherArray = [WeatherModel]()
    var city: CityModel?
    let refresher = UIRefreshControl()
    let locationManager = CLLocationManager()
    
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet weak var HourlyForecastTable: UITableView!
       
    override func viewDidLoad() {
        super.viewDidLoad()
        self.HourlyForecastTable.dataSource = self;
        self.HourlyForecastTable.addSubview(self.refresher)
        self.refresher.addTarget(self, action: #selector(self.handleRefresh(_:)), for: UIControl.Event.valueChanged)
        self.refresher.tintColor = UIColor.gray

        NotificationCenter.default.addObserver(self, selector: #selector(receivedLocationNotification(notification:)), name: .alocation, object: nil)
        if CLLocationManager.locationServicesEnabled() {
             self.locationManager.delegate = self
             self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
             self.locationManager.startUpdatingLocation()
         }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateOpenWeatherHourly()
    }
    
    @objc func receivedLocationNotification(notification: NSNotification){
        print("received notification")
    }

    func updateOpenWeatherHourly() {
        var parameters: [String:String]?
        let location = utils.fetchLastLocation()
        
        if (location.latitude != nil) {
            parameters = [
                "latitude": location.latitude!,
                "longitude": location.longitude!
            ]
        }
        let url = openWeather.buildURL(queryType: .hourly, parameters: parameters)
        openWeather.getHourly(url: url) {
            (weatherModelArray: [WeatherModel]?, city: CityModel?) -> Void in
            if let wm = weatherModelArray, let c = city {
                self.weatherArray = wm
                self.city = city
                DispatchQueue.main.async{
                    self.HourlyForecastTable.reloadData()
                    self.locationLabel.text = c.name
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.weatherArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Get a new or recycled cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "HourlyForecastCell", for: indexPath) as! HourlyForecastCell
        
        // Set the text on the cell with the description of the item
        // that s the nth index of items, where n = row this cell
        // will appear in the tableview
        let weatherCellData = self.weatherArray[indexPath.row]
                
        if let temp = weatherCellData.temp
        {
            cell.tempLabel?.text = String(format:"%.1f", temp) + " F"
        }

        if let humidity = weatherCellData.avehumidity {
            cell.humidityLabel?.text = String(format:"%.0f", humidity) + "%"
        }

        if let utcTime = weatherCellData.dt {
            let dateFormatter = DateFormatter()
            let date = Date(timeIntervalSince1970: Double(utcTime) )
            dateFormatter.dateFormat = "MMM dd HH:mm"
            let localDate = dateFormatter.string(from: date)
            cell.timeLabel?.text = localDate
        }
        
        if let description = weatherCellData.main_description {
            cell.conditionsLabel?.text = description
            cell.iconImage?.image = utils.switchConditionsImage(icon: description.lowercased())
        }
        if let wind_speed = weatherCellData.wind_speed {

            if let wind_dir = utils.windDirName(num: weatherCellData.wind_dir) {
                cell.windSpeedLabel?.text = wind_dir + " " + String(format:"%.0f", wind_speed) + " MPH"
            }
            else {
                cell.windSpeedLabel?.text = String(format:"%.0f", wind_speed) + " MPH"
            }
        }
        return cell
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        updateOpenWeatherHourly()
        refreshControl.endRefreshing()
    }

}

extension HourlyViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("error")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocation = manager.location else { return }
        print(locValue)
        self.locationManager.stopUpdatingLocation()
    }
}
