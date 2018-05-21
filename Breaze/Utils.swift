//
//  Utils.swift
//  Breaze
//
//  Created by Joe Hardy on 5/20/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit

class Utils {
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
