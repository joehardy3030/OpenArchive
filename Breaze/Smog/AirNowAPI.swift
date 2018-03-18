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

    static func smogForecast(fromJSON data: Data) -> SmogForecastResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard
            let jsonArray = jsonObject as? [[String:Any]]
                else {
                    return .failure(SmogError.invalidJSONData)
                }
        
            var finalSmogForecast = [SmogReading]()
            var finalSmogDays = [SmogDay]() // new
            var siteNames = [String]() // new s
            for smogForecastJSON in jsonArray {
                if let smogForecastReading = smogForecastReading(fromJSON: smogForecastJSON) {
                    finalSmogForecast.append(smogForecastReading)
                    //print(smogForecastReading)
                }
             }
            for smogReading in finalSmogForecast {
                if siteNames.contains(smogReading.siteName) {
                 //   print("already got one")
                //    print(smogReading.siteName)
                    let smogDay = finalSmogDays.first(where:{$0.siteName == smogReading.siteName})
                    //smogDay?.NO2 = 20
                    switch smogReading.parameter {
                    case "SO2":
                        smogDay?.SO2 = smogReading.AQI
                   //     print("SO2 \(smogDay?.SO2 ?? -1)")
                    case "NO2":
                        smogDay?.NO2 = smogReading.AQI
                     //   print("NO2 \(smogDay?.NO2 ?? -1)")
                    case "OZONE":
                        smogDay?.ozone = smogReading.AQI
                       // print("Ozone \(smogDay?.ozone ?? -1)")
                    case "PM2.5":
                        smogDay?.PM25 = smogReading.AQI
                       // print("PM2.5 \(smogDay?.PM25 ?? -1)")
                    default:
                        print("Fell through the switch")
                    }
                }
                else {
                    siteNames.append(smogReading.siteName)
                    let smogDay = smogForecastDay()
                    smogDay?.siteName = smogReading.siteName
                    switch smogReading.parameter {
                    case "SO2":
                        smogDay?.SO2 = smogReading.AQI
                        //print("SO2 \(smogDay?.SO2 ?? -1)")
                    case "NO2":
                        smogDay?.NO2 = smogReading.AQI
                        //print("NO2 \(smogDay?.NO2 ?? -1)")
                    case "OZONE":
                        smogDay?.ozone = smogReading.AQI
                       // print("Ozone \(smogDay?.ozone ?? -1)")
                    case "PM2.5":
                        smogDay?.PM25 = smogReading.AQI
                       // print("PM2.5 \(smogDay?.PM25 ?? -1)")
                    default:
                        print("Fell through the switch")
                    }
                 //   print("site name \(smogDay!.siteName)")
                    finalSmogDays.append(smogDay!)
                }
            }
            //  if siteNames.contain {
            // add a new instance of SmogDaya
            //  }
        //    print("count smogDays \(finalSmogDays.count)")
            for smogDay in finalSmogDays {
                print("siteName \(smogDay.siteName)")
                print("NO2 \(smogDay.NO2)")
                print("SO2 \(smogDay.SO2)")
                print("Ozone \(smogDay.ozone)")
                print("PM2.5 \(smogDay.PM25)")
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
       // print(parameter)
        return SmogReading(parameter: parameter,
                        AQI: AQI,
                        siteName: siteName)
    }
    
    private static func smogForecastDay() -> SmogDay? {
        let SO2 = -1
        let NO2 = -1
        let ozone = -1
        let PM25 = -1
        let siteName = "siteName"
        //print(parameter)
        return SmogDay(SO2: SO2,
                       NO2: NO2,
                       ozone: ozone,
                       PM25: PM25,
                       siteName: siteName)
    }
   
}

