//
//  OpenWeatherAPI.swift
//  Breaze
//
//  Created by Joe Hardy on 10/25/19.
//  Copyright © 2019 Carquinez. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

enum queryType {
    case current
    case hourly
}

class OpenWeatherAPI: NSObject {

    let utils = Utils()
    let apiKey = "263e9f27a9c219e9d7db30993b91c33b"
    let baseURLString = "https://api.openweathermap.org/data/2.5/"
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
            var url = baseURLString
            url += "forecast"
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
            completion(weatherModel)
          }
       }
    }

    func getHourly(url: String, completion: @escaping ([WeatherModel]?) -> Void) {
        Alamofire.request(url).responseJSON { response in
          if let json = response.result.value {
            let city = self.deserializeCity(fromJSON: json)
            print(city as Any)
            let weatherModelArray = self.deserializeHourly(fromJSON: json)
            completion(weatherModelArray)
          }
       }
    }
    
    private func deserializeCity(fromJSON json: Any) -> CityModel? {
        let json = JSON(json)
        let city = json["city"]
        let name = city["name"].string
        let country = city["country"].string
        let coordinates = ["latitude": city["coord"]["lat"].double,
                           "longitude": city["coord"]["lon"].double] as [String:Double?]?
        let population = city["population"].double
        let timezone = city["population"].double
        let sunrise = city["sunrise"].double
        let sunset = city["sunset"].double
                
        return CityModel(name: name,
                         country: country,
                         coordinates: coordinates,
                         population: population,
                         timezone: timezone,
                         sunrise: sunrise,
                         sunset: sunset)
    }

    private func deserializeHourly(fromJSON json: Any) -> [WeatherModel]? {
        var weatherModelArray = [WeatherModel]()
        let json = JSON(json)
        let list = json["list"]
        
        for (_,subJson):(String, JSON) in list {
            let weatherModel = deserializeWeatherModel(fromJSON: subJson)
            weatherModelArray.append(weatherModel)
        }
        return weatherModelArray
    }
    
    private func deserializeWeatherModel(fromJSON json: JSON) -> WeatherModel {
        
        let temp = json["main"]["temp"].double
        let high = json["main"]["temp_max"].double
        let low = json["main"]["temp_min"].double
        let icon = json["weather"][0]["icon"].string
        let main_description = json["weather"][0]["main"].string
        let conditions = json["weather"][0]["description"].string
        let humidity = json["main"]["humidity"].double

        return WeatherModel(temp: utils.convertKtoF(kelvin: temp),
                            high: utils.convertKtoF(kelvin: high),
                            low: utils.convertKtoF(kelvin: low),
                            icon: icon,
                            icon_url: nil,
                            main_description: main_description,
                            conditions: conditions,
                            avehumidity: humidity,
                            weekday_short: nil)
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
//        print(json)
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
