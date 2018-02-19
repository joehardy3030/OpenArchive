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
    //https://docs.airnowapi.org/CurrentObservationsByZip/query
//    case smogForecast = "https://www.airnowapi.org/aq/observation/zipCode/current/?format=application/json&zipCode=94530&distance=25&API_KEY=6127988D-CB19-4E37-969F-56F4B394D406"
    case smogForecast = "https://www.airnowapi.org/aq/data/?startDate=2018-02-16T02&endDate=2018-02-16T03&parameters=O3,PM25,PM10,NO2,SO2&BBOX=-122.448995,37.805168,-122.218282,37.995887&dataType=A&format=application/json&verbose=1&API_KEY=6127988D-CB19-4E37-969F-56F4B394D406"
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
    
//    static func smogForecast(fromJSON data: Data) -> SmogForecastResult {
 //       do {
  //          let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
         //   print(jsonObject)
            
           // var finalSmogForecast = [SmogHour]()
            //let finalSmogForecast = jsonObject
          //  return .success(finalSmogForecast)
      //  }
      //  catch let error {
      //      return .failure(error)
       // }
    //}


    
    static func smogForecast(fromJSON data: Data) -> SmogForecastResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard
            let jsonArray = jsonObject as? [[String:Any]]
                else {
                    return .failure(SmogError.invalidJSONData)
                }
        
            var finalSmogForecast = [SmogReading]()
            for smogForecastJSON in jsonArray {
                if let smogForecastReading = smogForecastReading(fromJSON: smogForecastJSON) {
                    finalSmogForecast.append(smogForecastReading)
                }
            }
            return .success(finalSmogForecast)
        }
        catch let error {
            return .failure(error)
        }
    }

    private static func smogForecastReading(fromJSON json: [String : Any]) -> SmogReading? {
        guard
            let parameter = json["Parameter"] as? String,
            let AQI = json["AQI"] as? Int,
            let siteName = json["SiteName"] as? String
            
            else {
                return nil
        }
        print(parameter)
        return SmogReading(parameter: parameter,
                        AQI: AQI,
                        siteName: siteName
        )
    }
    
}

