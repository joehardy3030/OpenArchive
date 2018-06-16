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
    case hourlyForecast = "/conditions/forecast/hourly/q"
    case simpleForecast = "/conditions/forecast/q"
}

struct WundergroundAPI {
    
    private static let baseURLString = "https://api.wunderground.com/api"
    private static let apiKey = "/ffd1b93b6a497308"
    private static let homeLocation = "/CA/El_Cerrito"
    private static let fileExtension = ".json"
    
    static var simpleForecastURL: URL {
        return wundergroundURL(method: .simpleForecast, parameters: nil)
    }
    
    static var hourlyForecastURL: URL {
        return wundergroundURL(method: .hourlyForecast, parameters: nil)
    }

    static func localSimpleForecastURL(paramaters: [String:String]?) -> URL {
        return wundergroundURL(method: .simpleForecast, parameters: paramaters)
    }

    // This private function returns the URL
    // It takes the Method as a parameter,
    // as well as a set of optional dictionary of query parameters
    private static func wundergroundURL(method: Method, parameters: [String:String]?) -> URL
    {
        //let components = URLComponents(string: method.rawValue)!
        var components = baseURLString
        let queryMethod = method.rawValue
        let location = homeLocation
        let fileExt = fileExtension
        
        let baseParameters = [
            "api_key": apiKey
        ]
        
//        components = components + baseParameters["api_key"]! + queryMethod + location + fileExt

        if parameters == nil {
            components = components + baseParameters["api_key"]! + queryMethod + location + fileExt
            print("El Cerrito")
        }
        else {
            components = components + baseParameters["api_key"]! + queryMethod + "/" + parameters!["latitude"]! + "," + parameters!["longitude"]! + fileExt
            print(parameters?["latitude"] ?? "")
            print(parameters?["longitude"] ?? "")
        }
        print(components)
        return URL(string: components)!
    }
    
    static func simpleForecast(fromJSON data: Data) -> SimpleForecastResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            guard
                let jsonDictionary = jsonObject as? [AnyHashable:Any],
                let conditionsDictionary = jsonDictionary["current_observation"] as? [AnyHashable: Any],
                let displayLocationDictionary = conditionsDictionary["display_location"] as? [AnyHashable: Any],
                let displayCity = displayLocationDictionary["city"] as? String,
                let forecastDictionary = jsonDictionary["forecast"] as? [AnyHashable: Any],
                let simpleForecastDictionary = forecastDictionary["simpleforecast"] as? [AnyHashable: Any],
                let forecastdaysArray = simpleForecastDictionary["forecastday"] as? [[String: Any]]
                else {
                    return .failure(WundergroundError.invalidJSONData)
                }
            print(jsonDictionary)
            print(displayCity)
            var finalSimpleForecast = [SimpleForecastDay]()
            for forecastdayJSON in forecastdaysArray {
                if let simpleForecastDay = simpleForecastDay(fromJSON: forecastdayJSON) {
                    finalSimpleForecast.append(simpleForecastDay)
                }
            }
            return .success(finalSimpleForecast, displayCity)
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
            let avehumidity = json["avehumidity"] as? Int,
            let dateDictionary = json["date"] as? [String:Any],
            let weekday_short = dateDictionary["weekday_short"] as? String
        
            else {
                return nil
        }
        return SimpleForecastDay(high: high,
                                 low: low,
                                 icon: icon,
                                 icon_url: icon_url,
                                 conditions: conditions,
                                 avehumidity: avehumidity,
                                 weekday_short: weekday_short)
    }

    static func hourlyForecast(fromJSON data: Data) -> HourlyForecastResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            guard
                let jsonDictionary = jsonObject as? [AnyHashable:Any],
                let hourlyForecastArray = jsonDictionary["hourly_forecast"] as? [[String: Any]]
                else {
                    return .failure(WundergroundError.invalidJSONData)
            }
            var finalHourlyForecast = [HourlyForecastHour]()
            for forecastHourJSON in hourlyForecastArray {
                //print(forecastHourJSON)
                if let hourlyForecastHour = hourlyForecastHour(fromJSON: forecastHourJSON) {
                    finalHourlyForecast.append(hourlyForecastHour)
                }
            }
            return .success(finalHourlyForecast)
        }
        catch let error {
            return .failure(error)
        }
    }
    
    private static func hourlyForecastHour(fromJSON json: [String : Any]) -> HourlyForecastHour? {
        guard
            let tempDictionary = json["temp"] as? [String:Any],
            let temp = tempDictionary["english"] as? String,
            let feelslikeDictionary = json["feelslike"] as? [String:Any],
            let feelslike = feelslikeDictionary["english"] as? String,
            let dewpointDictionary = json["dewpoint"] as? [String:Any],
            let dewpoint = dewpointDictionary["english"] as? String,
            let mslpDictionary = json["mslp"] as? [String:Any],
            let mslp = mslpDictionary["english"] as? String,
            let wspdDictionary = json["wspd"] as? [String:Any],
            let wspd = wspdDictionary["english"] as? String,
            let wdirDictionary = json["wdir"] as? [String:Any],
            let dir = wdirDictionary["dir"] as? String,
            let icon = json["icon"] as? String,
            let wx = json["wx"] as? String,
            let uvi = json["uvi"] as? String,
            let humidity = json["humidity"] as? String,
            let timeDictionary = json["FCTTIME"] as? [String:Any],
            let civil = timeDictionary["civil"] as? String
            
            else {
                return nil
        }
       
        return HourlyForecastHour(temp: temp,
                                  feelslike: feelslike,
                                  dewpoint: dewpoint,
                                  mslp: mslp,
                                  wspd: wspd,
                                  dir: dir,
                                  icon: icon,
                                  wx: wx,
                                  uvi: uvi,
                                  humidity: humidity,
                                  civil: civil)
    }


}


