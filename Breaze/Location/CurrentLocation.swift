//
//  CurrentLocation.swift
//  Breaze
//
//  Created by Joe Hardy on 4/2/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

class CurrentLocation {
    static let shared = CurrentLocation()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    init() {
    }
    
    func updateLocation() {
        appDelegate.locationManager.startUpdatingLocation()
    }
    
    func locationNotification(location: CLLocation?) {
        if let location = location {
            NotificationCenter.default.post(name: .newCurrentLocation, object: self, userInfo: ["location": location])
           // LocationsStorage.shared.saveCLLocationToDisk(location)
        }
    }
    
}

extension Notification.Name {
    static let newCurrentLocation = Notification.Name("newCurrentLocation")
}
