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
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation!
    var refresher: UIRefreshControl!
    // https://www.hackingwithswift.com/read/22/2/requesting-location-core-location
    var utils = Utils()
    var store = WeatherStore()
    var simpleForecastArray = [SimpleForecastDay]()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    struct startingLocation {
        var latitude: String?
        var longitude: String?
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refresher = UIRefreshControl()
        tableView.addSubview(refresher)
        refresher.addTarget(self, action: #selector(self.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        refresher.tintColor = UIColor.gray
        var location = startingLocation()
        //self.tableView.addSubview((self.refreshControl?)!)
        location = fetchLastLocation()
        print(location.latitude as Any)
        print(location.longitude as Any)
        if (location.latitude != nil) {
            let parameters = [
                "latitude": location.latitude!,
                "longitude": location.longitude!
            ]
            self.updateSimpleForecastData(paramaters: parameters)
        }
        else {
            self.updateSimpleForecastData(paramaters: nil)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(receivedLocationNotification(notification:)), name: .alocation, object: nil)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func receivedLocationNotification(notification: NSNotification){
        print("received notification")
        self.currentLocation = appDelegate.currentLocation

        DispatchQueue.main.async{
            let parameters = [
                "latitude": String(self.currentLocation.coordinate.latitude),
                "longitude": String(self.currentLocation.coordinate.longitude)
            ]
            self.updateSimpleForecastData(paramaters: parameters)
            print(self.currentLocation?.coordinate.latitude as Any)
            print(self.currentLocation?.coordinate.longitude as Any)
        }

    }
    
    func fetchLastLocation() -> startingLocation {
       // let data = [NSManagedObject]()
        var location = startingLocation()
        let context = appDelegate.persistentContainer.viewContext
        //  let entity = NSEntityDescription.entity(forEntityName: "LastLocation", in: context)
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "LastLocation")
        //request.predicate = NSPredicate(format: "age = %@", "12")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                print(data.value(forKey: "longitude") as! String)
                location.longitude = data.value(forKey: "longitude") as? String
                location.latitude = data.value(forKey: "latitude") as? String
            }
            
        } catch {
            print("Failed")
        }
        return location
    }
    
    func updateSimpleForecastData(paramaters: [String:String]?) {
        // Grab the HourlyForecast data and put it in the HourlyForecastData
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
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        // Do some reloading of data and update the table view's data source
        // Fetch more objects from a web service, for example...
        let parameters = [
            "latitude": String(self.currentLocation.coordinate.latitude),
            "longitude": String(self.currentLocation.coordinate.longitude)
        ]
        self.updateSimpleForecastData(paramaters: parameters)
        refreshControl.endRefreshing()
    }
    
/*    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(WeatherViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        refreshControl.tintColor = UIColor.gray
        
        return refreshControl
    }()
*/
}

