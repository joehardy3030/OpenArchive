//
//  BARTAPI.swift
//  Breaze
//
//  Created by Joe Hardy on 2/10/19.
//  Copyright © 2019 Carquinez. All rights reserved.
//

import Foundation

enum BARTError: Error {
    case invalidJSONData
}

struct BARTAPI {
    
  //  NSString *dataUrl = @"http://api.bart.gov/api/etd.aspx?cmd=etd&orig=deln&dir=s&key=MW9S-E7SL-26DU-VV8V";

    
    private static let baseURLString = "http://api.bart.gov/api/etd.aspx"
    private static let cmd = "etd"
    private static let orig = "deln"
    private static let dir = "s"
    private static let key = "MW9S-E7SL-26DU-VV8V"
    private static let and_sign = "&"
    private static let question_mark = "?"
    private static let widthLong = 0.25
    private static let heightLat = 0.25

    
    static func localBARTURL(location: [String:String]?) -> URL
        // create the URL for the HTTP get command for the smog API
    {
        var components = baseURLString
        if location == nil {
            components = components + question_mark + "cmd=" + cmd + and_sign +
                "orig=" + orig + and_sign + "dir=" + dir + and_sign + "key=" + key
        }
            
        else {
            let bBox = drawBox(location: location)
            components = components + question_mark + "cmd=" + cmd + and_sign +
                "orig=" + orig + and_sign + "dir=" + dir + and_sign + "key=" + key
        }
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
                    let smogDay = smogForecastDay()
                    smogDay?.siteName = smogReading.siteName
                    smogDaySwitch(smogReading: smogReading, smogDay: smogDay!)
                    
                    finalSmogDays.append(smogDay!)
                }
            }
            for smogDay in finalSmogDays {
                print("siteName \(smogDay.siteName)")
                print("NO2 \(smogDay.NO2)")
                print("SO2 \(smogDay.SO2)")
                print("Ozone \(smogDay.ozone)")
                print("PM2.5 \(smogDay.PM25)")
            }
            return .success(finalSmogDays)
            //return .success(finalSmogForecast)
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
