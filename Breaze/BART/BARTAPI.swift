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
 //   https://api.bart.gov/api/etd.aspx?cmd=etd&orig=deln&dir=s&key=MW9S-E7SL-26DU-VV8V&json=y
  //  https://api.bart.gov/api/etd.aspx?cmd=etd&orig=deln&dir=s&key=MW9S-E7SL-26DU-VV8Vjson=y
    
    private static let baseURLString = "https://api.bart.gov/api/etd.aspx"
    private static let cmd = "etd"
    private static let orig = "deln"
    private static let dir = "s"
    private static let key = "MW9S-E7SL-26DU-VV8V"
    private static let and_sign = "&"
    private static let question_mark = "?"
    private static let widthLong = 0.25
    private static let heightLat = 0.25
    private static let json_param = "y"

    
    static func localBARTURL(location: [String:String]?) -> URL
        // create the URL for the HTTP get command for the smog API
    {
        var components = baseURLString
        if location == nil {
            components = components + question_mark + "cmd=" + cmd + and_sign +
                "orig=" + orig + and_sign + "dir=" + dir + and_sign + "key=" + key +
                and_sign + "json=" + json_param
            print(components)
        }
            
        else {
            let bBox = drawBox(location: location)
            components = components + question_mark + "cmd=" + cmd + and_sign +
                "orig=" + orig + and_sign + "dir=" + dir + and_sign + "key=" + key +
                and_sign + "json=" + json_param
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
    
    // Take the data from the BART API and return a data BARTResult (part of BARTStore)
    // that has a single instance for each line
    static func BARTForecast(fromJSON data: Data) -> BARTResult {
        do {
            print(String(data: data, encoding: String.Encoding.utf8))
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            guard
                //let jsonArray = jsonObject as? [[String:Any]],
                let jsonDictionary = jsonObject as? [AnyHashable:Any],
                let rootDictionary = jsonDictionary["root"] as? [AnyHashable:Any],
                let stationArray = rootDictionary["station"] as? [[AnyHashable: Any]],
                let etdArray = stationArray[0]["etd"] as? [[AnyHashable: Any]]

                else {
                   // print("Fails right away")
                    return .failure(BARTError.invalidJSONData)
            }
            
            var finalBARTReading = [BARTReading]()
   
            for etd in etdArray {
                guard
                    let estimateArray = etd["estimate"] as? [[AnyHashable: Any]]
                    else {
                        return .failure(BARTError.invalidJSONData)
                }
                for estimate in estimateArray {
                    if let BARTEtdReading = BARTEtdReading(fromJSON: estimate) {
                        finalBARTReading.append(BARTEtdReading)
                    }
                }
                
            }
  
            for BARTEtdReading in finalBARTReading {
                print("numCars \(BARTEtdReading.numCars)")
                print("minToArrival \(BARTEtdReading.minToArrival)")
            }
            return .success(finalBARTReading)
        }
        catch let error {
            return .failure(error)
        }
    
}
    
    private static func BARTEtdReading(fromJSON etd: [AnyHashable : Any]) -> BARTReading? {
        guard
            let numCars = etd["length"] as? Int,
            let minToArrival = etd["minutes"] as? Int
            
            else {
                return nil
        }
        print(numCars)
        print(minToArrival)
        
        return BARTReading(numCars: numCars,
                           minToArrival: minToArrival)
    }
    
    
}
