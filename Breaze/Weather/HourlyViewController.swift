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
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var refresher: UIRefreshControl!
    var currentLocation: CLLocation!
    struct lastLocation {
        var latitude: String?
        var longitude: String?
    }
    
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet weak var HourlyForecastTable: UITableView!
       
    override func viewDidLoad() {
        super.viewDidLoad()
        self.HourlyForecastTable.dataSource = self;
        
        refresher = UIRefreshControl()
        self.HourlyForecastTable.addSubview(self.refresher)
        refresher.addTarget(self, action: #selector(self.handleRefresh(_:)), for: UIControl.Event.valueChanged)
        refresher.tintColor = UIColor.gray

        NotificationCenter.default.addObserver(self, selector: #selector(receivedLocationNotification(notification:)), name: .alocation, object: nil)
        self.currentLocation = appDelegate.currentLocation
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        var location = lastLocation()
        location = fetchLastLocation()
        if (location.latitude != nil) {
            let parameters = [
                "latitude": location.latitude!,
                "longitude": location.longitude!
            ]
            self.updateOpenWeatherHourly(parameters: parameters)
        }
        else {
            self.updateOpenWeatherHourly(parameters: nil)
        }
    }
    
    @objc func receivedLocationNotification(notification: NSNotification){
        print("received notification")
    }
    
    func fetchLastLocation() -> lastLocation {
        var location = lastLocation()
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "LastLocation")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                location.longitude = data.value(forKey: "longitude") as? String
                location.latitude = data.value(forKey: "latitude") as? String
            }
            
        } catch {
            print("Failed")
        }
        return location
    }

    func updateOpenWeatherHourly(parameters: [String:String]?) {
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
        // Do some reloading of data and update the table view's data source
        // Fetch more objects from a web service, for example...

        var parameters: [String:String]?
        parameters = setParameters()
        if (parameters != nil) {
            self.updateOpenWeatherHourly(parameters: parameters)
            print("Location not nil")
        }
        else {
            self.updateOpenWeatherHourly(parameters: nil)
            print("Location nil")
        }
        refreshControl.endRefreshing()
    }

    func setParameters() -> [String:String]? {
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
