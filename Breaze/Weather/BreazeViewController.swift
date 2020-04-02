//
//  BreazeViewController.swift
//  Breaze
//
//  Created by Joe Hardy on 3/30/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class BreazeViewController: UIViewController  {

    var utils = Utils()
    let locationManager = CLLocationManager()
    var openWeather = OpenWeatherAPI()
    var weatherArray = [WeatherModel]()
    var city: CityModel?
    let refresher = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.refresher.addTarget(self, action: #selector(self.handleRefresh(_:)), for: UIControl.Event.valueChanged)
        self.refresher.tintColor = UIColor.gray
        NotificationCenter.default.addObserver(self, selector: #selector(receivedLocationNotification(notification:)), name: .alocation, object: nil)
        if CLLocationManager.locationServicesEnabled() {
             self.locationManager.delegate = self
             self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
         }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func receivedLocationNotification(notification: NSNotification){
         print("received notification")
    }

    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        refreshControl.endRefreshing()
    }

}

extension BreazeViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("Breaze controller location error")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
    }
}
