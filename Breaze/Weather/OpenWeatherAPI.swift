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
    case current
    case daily
    case hourly
}

class OpenWeatherAPI: NSObject {

    let utils = Utils()
    let apiKey = "263e9f27a9c219e9d7db30993b91c33b"
    let baseURLString = "https://api.openweathermap.org/data/2.5/"
    let urlString = "https://api.openweathermap.org/data/2.5/weather?q=London,uk&APPID=263e9f27a9c219e9d7db30993b91c33b"
    let forecastURLString = "api.openweathermap.org/data/2.5/forecast/daily?lat={lat}&lon={lon}&cnt={cnt}"
    let cityLocation = "Berkeley,us"
    struct lastLocation {
        var latitude: String?
        var longitude: String?
    }
    
    func buildURL(queryType: queryType, parameters: [String:String]?) -> String {
                
        var lat = String()
        var lon = String()
        
        if let latLon = parameters {
            lat = latLon["latitude"]!
            lon = latLon["longitude"]!
        }
        
        switch queryType {
        case .current:
            var url = baseURLString
            url += "weather"
            url += "?lat="
            url += lat
            url += "&lon="
            url += lon
            url += "&APPID="
            url += apiKey
            return url
        case .hourly:
            return baseURLString
        case .daily:
            var url = baseURLString
            url += "forecast/daily"
            url += "?lat="
            url += lat
            url += "&lon="
            url += lon
            url += "&cnt=16"
            url += "&APPID="
            url += apiKey
            return url
        }
    }
    
    func getCurrent(url: String, completion: @escaping (WeatherModel?) -> Void) {
        Alamofire.request(url).responseJSON { response in
          if let json = response.result.value {
            let weatherModel = self.deserializeCurrent(fromJSON: json)
            //print(weatherModel as Any)
            completion(weatherModel)
          }
       }
    }

    func getDaily(url: String, completion: @escaping ([WeatherModel]?) -> Void) {
        Alamofire.request(url).responseJSON { response in
          if let json = response.result.value {
            let weatherModelArray = self.deserializeDaily(fromJSON: json)
            //print(weatherModel as Any)
            completion(weatherModelArray)
          }
       }
    }

    private func deserializeDaily(fromJSON json: Any) -> [WeatherModel]? {
        guard
            let json = json as? [String:Any],
            let _ = json["base"] as? String,
            let weather_dict = json["weather"] as? [[String:Any]]
            else {
                return [WeatherModel]()
        }
        let weather = weather_dict[0]
        guard
            let description = weather["description"] as? String,
            let icon = weather["icon"] as? String,
            let main_description = weather["main"] as? String,
            let main = json["main"] as? [String:Any],
            let temp = main["temp"] as? Double,
            let high = main["temp_max"] as? Double,
            let low = main["temp_min"] as? Double,
            let humidity = main["humidity"] as? Double
            else {
                return [WeatherModel]()
        }
        print(json)

        return [WeatherModel]()
       /* return WeatherModel(temp: utils.convertKtoF(kelvin: temp),
                            high: utils.convertKtoF(kelvin: high),
                            low: utils.convertKtoF(kelvin: low),
                            icon: icon,
                            icon_url: nil,
                            main_description: main_description,
                            conditions: description,
                            avehumidity: humidity,
                            weekday_short: nil)
        */
    }
    
    private func deserializeCurrent(fromJSON json: Any) -> WeatherModel? {
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
            let main_description = weather["main"] as? String,
            let main = json["main"] as? [String:Any],
            let temp = main["temp"] as? Double,
            let high = main["temp_max"] as? Double,
            let low = main["temp_min"] as? Double,
            let humidity = main["humidity"] as? Double
            else {
                return nil
        }
        print(json)
        return WeatherModel(temp: utils.convertKtoF(kelvin: temp),
                            high: utils.convertKtoF(kelvin: high),
                            low: utils.convertKtoF(kelvin: low),
                            icon: icon,
                            icon_url: nil,
                            main_description: main_description,
                            conditions: description,
                            avehumidity: humidity,
                            weekday_short: nil)
        
    }

}
