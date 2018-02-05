//
//  WundergroundAPI.swift
//  Breaze
//
//  Created by Joseph Hardy on 2/1/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import Foundation

enum Method: String {
    case simpleForecast = "https://api.wunderground.com/api/ffd1b93b6a497308/conditions/forecast/q/CA/El_Cerrito.json"
    case hourlyForecast = "https://api.wunderground.com/api/ffd1b93b6a497308/conditions/forecast/hourly/q/CA/El_Cerrito.json"
}

struct WundergroundAPI {
 
    static var simpleForecastURL: URL {
        return wundergroundURL(method: .simpleForecast, parameters: nil)
    }
    
    static var hourlyForecastURL: URL {
        return wundergroundURL(method: .hourlyForecast, parameters: nil)
    }

    // This private function returns the URL
    // It takes the Method as a parameter,
    // as well as a set of optional dictionory of query parameters
    private static func wundergroundURL(method: Method, parameters: [String:String]?) -> URL
    {
        let components = URLComponents(string: method.rawValue)!

        print(components.url!)
        return components.url!
    }
}


