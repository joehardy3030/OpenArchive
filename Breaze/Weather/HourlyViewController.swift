//
//  HourlyViewController.swift
//  Breaze
//
//  Created by Joe Hardy on 5/8/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit
import CoreLocation

class HourlyViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    
    var utils = Utils()
    var store = WeatherStore()
    var hourlyForecastArray = [HourlyForecastHour]()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var currentLocation: CLLocation!
    
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet weak var HourlyForecastTable: UITableView!
       
    override func viewDidLoad() {
        super.viewDidLoad()
        self.HourlyForecastTable.dataSource = self;
        self.HourlyForecastTable.addSubview(self.refreshControl)
        NotificationCenter.default.addObserver(self, selector: #selector(receivedLocationNotification(notification:)), name: .alocation, object: nil)
        self.currentLocation = appDelegate.currentLocation
        print(self.currentLocation?.coordinate.latitude as Any)
       // updateHourlyForecastData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let parameters = [
            "latitude": String(self.currentLocation.coordinate.latitude),
            "longitude": String(self.currentLocation.coordinate.longitude)
        ]
        self.updateHourlyForecastData(parameters: parameters)
    }
    
    @objc func receivedLocationNotification(notification: NSNotification){
       //  DispatchQueue.main.async{
            print("received notification")
       // }
    }
    
    func updateHourlyForecastData(parameters: [String:String]?) {
        // Grab the HourlyForecast data and put it in the HourlyForecastData
        store.fetchLocalHourlyForecast(parameters: parameters) {
            (HourlyForecastResult) -> Void in
            switch HourlyForecastResult {
            case let .success(hourlyForecast, displayCity):
                self.hourlyForecastArray = hourlyForecast
                print("count hourly \(self.hourlyForecastArray.count)")
                DispatchQueue.main.async{
                    self.HourlyForecastTable.reloadData()
                    self.locationLabel.text = displayCity
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.hourlyForecastArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Get a new or recycled cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "HourlyForecastCell", for: indexPath) as! HourlyForecastCell
        
        // Set the text on the cell with the description of the item
        // that s the nth index of items, where n = row this cell
        // will appear in the tableview
        let weatherCellData = self.hourlyForecastArray[indexPath.row]
        
        cell.tempLabel?.text = weatherCellData.temp + " F"
        cell.humidityLabel?.text = weatherCellData.humidity + "%"
        cell.timeLabel?.text = weatherCellData.civil
        cell.windSpeedLabel?.text = weatherCellData.dir + "  " + weatherCellData.wspd + " MPH"
        cell.conditionsLabel?.text = utils.switchConditionsText(icon: weatherCellData.icon)
        cell.iconImage?.image = utils.switchConditionsImage(icon: weatherCellData.icon)
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //If the triggered item is the "showHourlyDetail" segue
        switch segue.identifier {
        case "showHourlyDetail"?:
            if let row = HourlyForecastTable.indexPathForSelectedRow?.row {
                // Get the HourlyForecastHour associated with this row and pass it along
                let hourlyForecastHour = self.hourlyForecastArray[row]
                let hourlyDetailViewController = segue.destination as! HourlyDetailViewController
                hourlyDetailViewController.hourlyForecastHour = hourlyForecastHour
            }
        default:
            preconditionFailure("Unexpected segue identifier")
        }
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        // Do some reloading of data and update the table view's data source
        // Fetch more objects from a web service, for example...
        let parameters = [
            "latitude": String(self.currentLocation.coordinate.latitude),
            "longitude": String(self.currentLocation.coordinate.longitude)
        ]
        self.updateHourlyForecastData(parameters: parameters)
        refreshControl.endRefreshing()
    }
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(HourlyViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        refreshControl.tintColor = UIColor.gray
        
        return refreshControl
    }()

    
}
