//
//  OpenWeatherAPI.swift
//  Breaze
//
//  Created by Joe Hardy on 10/25/19.
//  Copyright © 2019 Carquinez. All rights reserved.
//

import UIKit
import Alamofire

enum queryType {
    case daily
    case hourly
    case sixteenDay
}

class OpenWeatherAPI: NSObject {

    let apiKey = "263e9f27a9c219e9d7db30993b91c33b"
    let baseURLString = "https://api.openweathermap.org/data/2.5/weather"
    let urlString = "https://api.openweathermap.org/data/2.5/weather?q=London,uk&APPID=263e9f27a9c219e9d7db30993b91c33b"
    let cityLocation = "London,uk"
    struct lastLocation {
        var latitude: String?
        var longitude: String?
    }
    
    func buildURL(queryType: queryType) -> String {
        switch queryType {
        case .daily:
            var url = baseURLString
            url += "?q="
            url += cityLocation
            url += "&APPID="
            url += apiKey
            return url
        case .hourly:
            return baseURLString
        default:
            return baseURLString
        }
    }
    
    func getWeather(url: String, completion: @escaping (Any) -> Void) {
        Alamofire.request(url).responseJSON { response in
          if let json = response.result.value {
            completion(json)
            //print("JSON: \(json)") // serialized json response
          }
       }
    }
        
    //    ?q=London,uk&APPID=263e9f27a9c219e9d7db30993b91c33b"
    
/*
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
 */
}
