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
    
    func getWeather(url: String, completion: @escaping (WeatherModel?) -> Void) {
        Alamofire.request(url).responseJSON { response in
          if let json = response.result.value {
            let weatherModel = self.deserializeCurrentWeather(fromJSON: json)
            //print(weatherModel as Any)
            completion(weatherModel)
          }
       }
    }
    
    private func deserializeCurrentWeather(fromJSON json: Any) -> WeatherModel? {
        guard
            let json = json as? [String:Any],
            let _ = json["base"] as? String,
            let weather_dict = json["weather"] as? [[String:Any]]
            else {
                return nil
        }
        let weather = weather_dict[0]
        guard
            let description = weather["description"] as? String,
            let icon = weather["icon"] as? String,
            let main = json["main"] as? [String:Any],
            let temp = main["temp"] as? Double,
            let high = main["temp_max"] as? Double,
            let low = main["temp_min"] as? Double,
            let humidity = main["humidity"] as? Double
            else {
                return nil
        }
       
        return WeatherModel(temp: temp,
                            high: high,
                            low: low,
                            icon: icon,
                            icon_url: nil,
                            conditions: description,
                            avehumidity: humidity,
                            weekday_short: nil)
        
    }

}
