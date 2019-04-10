//
//  Utils.swift
//  Breaze
//
//  Created by Joe Hardy on 5/20/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class Utils {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    struct lastLocation {
        var latitude: String?
        var longitude: String?
    }

    func fetchLastLocation() -> lastLocation {
        
        var location = lastLocation()
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "LastLocation")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                // print(data.value(forKey: "longitude") as! String)
                location.longitude = data.value(forKey: "longitude") as? String
                location.latitude = data.value(forKey: "latitude") as? String
            }
            
        } catch {
            print("Failed")
        }
        return location
    }
    
    func switchConditionsText(icon: String) -> String {
        var conditions: String
        switch icon {
        case "clear":
            conditions = "Clear"
        case "rain":
            conditions = "Rain"
        case "chancerain":
            conditions = "Chance of Rain"
        case "tstorms":
            conditions = "Thunder Storms"
        case "mostlycloudy":
            conditions = "Mostly Cloudy"
        case "partlycloudy":
            conditions = "Partly Cloudy"
        case "cloudy":
            conditions = "Cloudy"
        case "fog":
            conditions = "Fog"
        default:
            conditions = icon
        }
     return conditions
    }
    
    func switchConditionsImage(icon: String) -> UIImage {
        var iconImage: UIImage
        switch icon {
        case "clear":
            iconImage = UIImage(named: icon)!
        case "rain":
            iconImage = UIImage(named: icon)!
        case "chancerain":
            iconImage = UIImage(named: "rain")!
        case "tstorms":
            iconImage = UIImage(named: "rain")!
        case "mostlycloudy":
            iconImage = UIImage(named: icon)!
        case "partlycloudy":
            iconImage = UIImage(named: icon)!
        case "cloudy":
            iconImage = UIImage(named: icon)!
        case "fog":
            iconImage = UIImage(named: icon)!
        default:
            iconImage = UIImage(named: "cloudy")!
        }
        return iconImage
    }
    
}
