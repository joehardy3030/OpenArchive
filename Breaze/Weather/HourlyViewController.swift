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

class HourlyViewController: BreazeViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet weak var HourlyForecastTable: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.HourlyForecastTable.addSubview(self.refresher)
        self.HourlyForecastTable.dataSource = self;
        self.locationManager.startUpdatingLocation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateOpenWeatherHourly()
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
            dateFormatter.dateFormat = "MMM dd, h:mm a"
            let localDate = dateFormatter.string(from: date)
            cell.timeLabel?.text = localDate
        }
        
        if let description = weatherCellData.main_description {
            cell.conditionsLabel?.text = description
            cell.iconImage?.image = utils.switchConditionsImage(icon: description.lowercased())
        }
        if let wind_speed = weatherCellData.wind_speed {

            if let wind_dir = Utils.windDirName(num: weatherCellData.wind_dir) {
                cell.windSpeedLabel?.text = wind_dir + " " + String(format:"%.0f", wind_speed) + " MPH"
            }
            else {
                cell.windSpeedLabel?.text = String(format:"%.0f", wind_speed) + " MPH"
            }
        }
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = HourlyForecastTable.indexPathForSelectedRow else { return }
        if let target = segue.destination as? HourlyDetailViewController {
            let weatherCellData = self.weatherArray[indexPath.row]
            target.hourForecast = weatherCellData
        }
    }
    
    @objc override func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.updateOpenWeatherHourly()
        refreshControl.endRefreshing()
    }

}

extension HourlyViewController {
    
    override func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocation = manager.location else { return }
        print(locValue)
        self.locationManager.stopUpdatingLocation()
        //updateOpenWeatherHourly()
    }
}
