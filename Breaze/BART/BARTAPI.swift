//
//  BARTAPI.swift
//  Breaze
//
//  Created by Joe Hardy on 2/10/19.
//  Copyright © 2019 Carquinez. All rights reserved.
//

import Foundation
import SwiftyJSON
import CoreLocation

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
    private static let json_param = "y"
    // https://api.bart.gov/api/stn.aspx?cmd=stns&key=MW9S-E7SL-26DU-VV8V&json=y
    
    static func localBARTURL(location: [String:String]?, station: BARTStationCodable, direction: String) -> URL
        // create the URL for train times
    {
        var components = baseURLString
        
        if let abbr = station.abbr {
            components = components + question_mark + "cmd=" + cmd + and_sign +
                "orig=" + abbr + and_sign + "dir=" + direction + and_sign + "key=" + key +
                and_sign + "json=" + json_param
        }
        
        return URL(string: components)!
    }
    
    static func readBARTstnsJSON() -> [BARTStationCodable] {
        var jsonObj = JSON()
        if let path = Bundle.main.path(forResource: "stns", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
                jsonObj = try JSON(data: data)
              //  print("jsonData:\(jsonObj)")
            } catch let error {
                print("parse error: \(error.localizedDescription)")
            }
        } else {
            print("Invalid filename/path.")
        }
        let BARTStations = deserializeBARTstns(json: jsonObj)
        return BARTStations
    }
    
    static func deserializeBARTstns(json: JSON) -> [BARTStationCodable] {
        var bartStns = [BARTStationCodable]()
        
        let root = json["root"]
        let stations = root["stations"]
        let station = stations["station"]
        
        for stn in station {
            let (_, jsonStn) = stn
            let bartStn = BARTStationCodable(address: jsonStn["abbr"].string,
                                             city: jsonStn["city"].string,
                                             zipcode: jsonStn["zipcode"].int,
                                             abbr: jsonStn["abbr"].string,
                                             name: jsonStn["name"].string,
                                             gtfs_latitude: jsonStn["gtfs_latitude"].double,
                                             gtfs_longitude: jsonStn["gtfs_longitude"].double)
            
            bartStns.append(bartStn)
        }
        return bartStns
    }
    
    static func findStationWithAbbr(abbr: String?) -> BARTStationCodable {
        let BARTStations = readBARTstnsJSON()
        let abbrs = BARTStations.map { $0.abbr }
        if let i = abbrs.firstIndex(of: abbr) {
            return BARTStations[i]
        }
        else { return BARTStations[0] }
    }
    
    static func findClosestStation(currentLocation: CLLocation) -> BARTStationCodable {
        var dists = [Double]()
        let stns = readBARTstnsJSON()
        
        for stn in stns {
            let dist = currentLocation.distance(from: currentLocation)
            print(stn.abbr as Any)
            print(dist)
        }
        return BARTStationCodable(address: nil, city: nil, zipcode: nil, abbr: nil, name: nil, gtfs_latitude: nil, gtfs_longitude: nil)
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
  
            finalBARTReading.sort (by: {
                Int($0.minToArrival) ?? 0 < Int($1.minToArrival) ?? 0
            })
            
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
