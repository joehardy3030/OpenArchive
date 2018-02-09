//
//  WundergroundAPI.swift
//  Breaze
//
//  Created by Joseph Hardy on 2/1/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import Foundation

enum WundergroundError: Error {
    case invalidJSONData
}

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
    
    static func simpleForecast(fromJSON data: Data) -> SimpleForecastResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            //print(jsonObject)
            guard
                let jsonDictionary = jsonObject as? [AnyHashable:Any],
               // let currentObservationDictionary = jsonDictionary["current_observation"] as? [String:Any],
                let forecastDictionary = jsonDictionary["forecast"] as? [AnyHashable: Any],
                let simpleForecastDictionary = forecastDictionary["simpleforecast"] as? [AnyHashable: Any],
                let textForecastDictionary = forecastDictionary["txt_forecast"] as? [AnyHashable: Any],
                let forecastdaysArray = simpleForecastDictionary["forecastday"] as? [[String: Any]]
                else {
                    return .failure(WundergroundError.invalidJSONData)
            }
            var finalSimpleForecast = [SimpleForecastDay]()
            for forecastdayJSON in forecastdaysArray {
                if let simpleForecastDay = simpleForecastDay(fromJSON: forecastdayJSON) {
                    finalSimpleForecast.append(simpleForecastDay)
                    print(forecastdayJSON)
                    print("High \(simpleForecastDay.high), low \(simpleForecastDay.low), icon \(simpleForecastDay.icon)")
                    print(simpleForecastDay.icon_url)
                //    print(simpleForecastDay.avehumidity)
                }
            }
            return .success(finalSimpleForecast)
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
            let icon_url = json["icon_url"] as? String
           // let avehumidity = json["avehumidity"] as? String
        
            else {
                return nil
        }
      //  print(avehumidity)
        return SimpleForecastDay(high: high,
                                 low: low,
                                 icon: icon,
                                 icon_url: icon_url)
    }

    static func hourlyForecast(fromJSON data: Data) -> HourlyForecastResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            var finalHourlyForecast = [HourlyForecastHour]()
            return .success(finalHourlyForecast)
        }
        catch let error {
            return .failure(error)
        }
    }

}


