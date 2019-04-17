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
    
    private static let baseURLString = "https://api.bart.gov/api/etd.aspx"
    private static let cmd = "etd"
    private static let orig = "mont"
    private static let dir = "n"
    private static let key = "MW9S-E7SL-26DU-VV8V"
    private static let and_sign = "&"
    private static let question_mark = "?"
    private static let widthLong = 0.25
    private static let heightLat = 0.25
    private static let json_param = "y"
    
    static func localBARTURL(location: [String:String]?, inOut: Int) -> URL
        // create the URL for the HTTP get command for the smog API
    {
        let inboundOrig = "deln"
        let outboundOrig = "mont"
        let inboundDir = "s"
        let outboundDir = "n"
        var components = baseURLString

        if inOut == 0 {
            components = components + question_mark + "cmd=" + cmd + and_sign +
                "orig=" + inboundOrig + and_sign + "dir=" + inboundDir + and_sign + "key=" + key +
                and_sign + "json=" + json_param
        }
        else {
            components = components + question_mark + "cmd=" + cmd + and_sign +
                "orig=" + outboundOrig + and_sign + "dir=" + outboundDir + and_sign + "key=" + key +
                and_sign + "json=" + json_param
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
    
    // Take the data from the BART API and return a data BARTResult (part of BARTStore)
    // that has a single instance for each line
    static func BARTForecast(fromJSON data: Data) -> BARTResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            guard
                let jsonDictionary = jsonObject as? [AnyHashable:Any],
                let rootDictionary = jsonDictionary["root"] as? [AnyHashable:Any],
                let stationArray = rootDictionary["station"] as? [[AnyHashable: Any]],
                let etdArray = stationArray[0]["etd"] as? [[AnyHashable: Any]]

                else {
                    return .failure(BARTError.invalidJSONData)
            }
          
            var finalBARTReading = [BARTReading]()
   
            for etd in etdArray {
                guard
                    let estimateArray = etd["estimate"] as? [[String: Any]],
                    let destination = etd["destination"] as? String
                    
                    else {
                        return .failure(BARTError.invalidJSONData)
                }
              //  print(destination)
                for estimate in estimateArray {
                    if let BARTEtdReading = BARTEtdReading(fromJSON: estimate, destination: destination) {
                        finalBARTReading.append(BARTEtdReading)
                    }
                }
                
            }
  
            finalBARTReading.sort {
                $0.minToArrival < $1.minToArrival
            }
            
            return .success(finalBARTReading)
        }
        catch let error {
            return .failure(error)
        }
    
}
    // Take in a chunch of JSON from BARTForecast and
    // return a BARTReading
    private static func BARTEtdReading(fromJSON estimate: [String : Any], destination: String) -> BARTReading? {
        guard
            let numCars = estimate["length"] as? String,
            let minToArrival = estimate["minutes"] as? String,
            let lineColor = estimate["color"] as? String
            
            else {
                return nil
        }
      //  print(destination)
        return BARTReading(numCars: numCars,
                           minToArrival: minToArrival,
                           lineColor: lineColor,
                           destination: destination)
    }
    
    
}
