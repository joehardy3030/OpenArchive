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

struct AirNowAPI {
    
    private static let baseURLString = "https://www.airnowapi.org/aq/data/"
    private static let parameters = "O3,PM25,NO2"
    private static let bBox = "-122.448995,37.805168,-122.218282,37.995887"
    private static let dataType = "A"
    private static let format = "application/json"
    private static let verbose = "1"
    private static let apiKey = "6127988D-CB19-4E37-969F-56F4B394D406"
    private static let and_sign = "&"
    private static let question_mark = "?"
    private static let widthLong = 0.5
    private static let heightLat = 0.5
    
    static func localSmogURL(location: [String:String]?) -> URL
    // create the URL for the HTTP get command for the smog API
    {
        var components = baseURLString
        if location == nil {
            components = components + question_mark + "parameters=" + parameters + and_sign +
                "BBOX=" + bBox + and_sign + "dataType=" + dataType + and_sign + "format=" + format +
                and_sign + "verbose=" + verbose + and_sign + "API_KEY=" + apiKey
        }
            
        else {
            let bBox = drawBox(location: location)
            components = components + question_mark + "parameters=" + parameters + and_sign +
                "BBOX=" + bBox! + and_sign + "dataType=" + dataType + and_sign + "format=" + format +
                and_sign + "verbose=" + verbose + and_sign + "API_KEY=" + apiKey
        }
        print(components)
        return URL(string: components)!
    }
    
    static private func drawBox(location:[String:String]?) -> String? {
        let midLatitudeString = location!["latitude"]
        let midLatitudeFloat = (midLatitudeString! as NSString).doubleValue
        let topLatitudeFloat = midLatitudeFloat + heightLat
        let bottomLatitudeFloat = midLatitudeFloat - heightLat

        let midLongitudeString = location!["longitude"]
        let midLongitudeFloat = (midLongitudeString! as NSString).doubleValue
        let rightLongitudeFloat = midLongitudeFloat + widthLong
        let leftLongitudeFloat = midLongitudeFloat - widthLong
        
        let boxString = String(leftLongitudeFloat) + "," +  String(bottomLatitudeFloat) + "," + String(rightLongitudeFloat) + "," + String(topLatitudeFloat)
        print("boxString")
        print(boxString)
        
        return boxString
    }
    
    // Take the data from the air quality API and return a data SmogForecastResult
    // that has a single instance for each location
    static func smogForecast(fromJSON data: Data) -> SmogForecastResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard
            let jsonArray = jsonObject as? [[String:Any]]
                else {
                    return .failure(SmogError.invalidJSONData)
                }
            
            // finalSmogForecast is an array of SmogReading intstances that gives you all
            // the individual value readings from that call -- one instance per pollutant per location
            // finalSmogDays is an array of SmogDay that gives you one instance per location per
            // per call, wrapping all the reading types
            
            var finalSmogForecast = [SmogReading]()
            var finalSmogDays = [SmogDay]()
            var siteNames = [String]()
            for smogForecastJSON in jsonArray {
                if let smogForecastReading = smogForecastReading(fromJSON: smogForecastJSON) {
                    finalSmogForecast.append(smogForecastReading)
                }
             }
            for smogReading in finalSmogForecast {
                if siteNames.contains(smogReading.siteName) {
                    let smogDay = finalSmogDays.first(where:{$0.siteName == smogReading.siteName})
                    smogDaySwitch(smogReading: smogReading, smogDay: smogDay!)
                }
                else {
                    siteNames.append(smogReading.siteName)
                    let smogDay = SmogDay(SO2: nil, NO2: nil, ozone: nil, PM25: nil, siteName: nil)
                    smogDay.siteName = smogReading.siteName
                    smogDaySwitch(smogReading: smogReading, smogDay: smogDay)
                    finalSmogDays.append(smogDay)
                }
            }
            return .success(finalSmogDays)
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
        return SmogReading(parameter: parameter,
                        AQI: AQI,
                        siteName: siteName)
    }
    
    private static func smogDaySwitch(smogReading: SmogReading, smogDay: SmogDay) {
        switch smogReading.parameter {
        case "SO2":
            smogDay.SO2 = smogReading.AQI
        case "NO2":
            smogDay.NO2 = smogReading.AQI
        case "OZONE":
            smogDay.ozone = smogReading.AQI
        case "PM2.5":
            smogDay.PM25 = smogReading.AQI
        default:
            print("Fell through the switch")
        }
    }

   
}

