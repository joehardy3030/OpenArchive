//
//  AQSAPI.swift
//  Breaze
//
//  Created by Joseph Hardy on 2/1/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import Foundation

enum SmogError: Error {
    case invalidJSONData
}

enum AQSURLMethod: String {
    case smogForecast = "https://api.wunderground.com/api/ffd1b93b6a497308/conditions/forecast/q/CA/El_Cerrito.json"
}

struct AQSAPI {
    
    static var smogForecastURL: URL {
        return smogURL(method: .smogForecast, parameters: nil)
    }
    
    // This private function returns the URL
    // It takes the Method as a parameter,
    // as well as a set of optional dictionory of query parameters
    private static func smogURL(method: AQSURLMethod, parameters: [String:String]?) -> URL
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

    private static func simpleForecastDay(fromJSON json: [String : Any]) -> SimpleForecastDay? {
        guard
            let highDictionary = json["high"] as? [String:Any],
            let high = highDictionary["fahrenheit"] as? String,
            let lowDictionary = json["low"] as? [String:Any],
            let low = lowDictionary["fahrenheit"] as? String,
            let icon = json["icon"] as? String,
            let icon_url = json["icon_url"] as? String,
            let conditions = json["conditions"] as? String,
            let avehumidity = json["avehumidity"] as? Int
            
            else {
                return nil
        }
        return SimpleForecastDay(high: high,
                                 low: low,
                                 icon: icon,
                                 icon_url: icon_url,
                                 conditions: conditions,
                                 avehumidity: avehumidity)
    }
    
}


