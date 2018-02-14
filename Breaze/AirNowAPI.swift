//
//  AirNowAPI.swift
//  Breaze
//
//  Created by Joseph Hardy on 2/13/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import Foundation

enum SmogError: Error {
    case invalidJSONData
}

enum AirNowMethod: String {
    case smogForecast = "https://www.airnowapi.org/aq/observation/zipCode/current/?format=application/json&zipCode=94530&distance=25&API_KEY=6127988D-CB19-4E37-969F-56F4B394D406"
    case weatherForecast = "https://api.wunderground.com/api/ffd1b93b6a497308/conditions/forecast/q/CA/El_Cerrito.json"
}

struct AirNowAPI {
    
    static var smogForecastURL: URL {
        return smogURL(method: .smogForecast, parameters: nil)
    }
    
    // This private function returns the URL
    // It takes the Method as a parameter,
    // as well as a set of optional dictionory of query parameters
    private static func smogURL(method: AirNowMethod, parameters: [String:String]?) -> URL
    {
        let components = URLComponents(string: method.rawValue)!
        
        print(components.url!)
        return components.url!
    }
    
    static func smogForecast(fromJSON data: Data) -> SmogForecastResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            print(jsonObject)
            
            var finalSmogForecast = [SmogHour]()
            //let finalSmogForecast = jsonObject
            return .success(finalSmogForecast)
        }
        catch let error {
            return .failure(error)
        }
    }
    
    private static func smogForecastHour(fromJSON json: [String : Any]) -> SmogHour? {
        guard
            let ppm25 = json["ppm25"] as? String,
            let ozone = json["ozone"] as? String
            
            else {
                return nil
        }
        return SmogHour(ppm25: ppm25,
                        ozone: ozone)
    }
    
}

