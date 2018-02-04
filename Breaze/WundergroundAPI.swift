//
//  WundergroundAPI.swift
//  Breaze
//
//  Created by Joseph Hardy on 2/1/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import Foundation

enum Method: String {
    // dataUrl = @"http://api.wunderground.com/api/ffd1b93b6a497308/conditions/forecast/q/CA/El_Cerrito.json";
    //case simpleForecast = "conditions/forecast/q/"
    case simpleForecast = "https://api.wunderground.com/api/ffd1b93b6a497308/conditions/forecast/q/CA/El_Cerrito.json"
}

struct WundergroundAPI {
    // This is the base URL for the API
  //  private static let baseURLString = "http://api.wunderground.com/api/"
   // private static let apiKey = "ffd1b93b6a497308"

    static var simpleForecastURL: URL {
        // return wundergroundURL(method: .simpleForecast, parameters: ["extras": "url_h,date_taken"])
        return wundergroundURL(method: .simpleForecast, parameters: nil)
    }

    // This private function returns the URL
    // It takes the Method as a parameter,
    // as well as a set of optional dictionory of query parameters
    private static func wundergroundURL(method: Method, parameters: [String:String]?) -> URL
    {
        let components = URLComponents(string: method.rawValue)!
        
    //    var components = URLComponents(string: baseURLString)!
        
     //   var queryItems = [URLQueryItem]()
        
      //  let baseParams = ["method": method.rawValue,
        //                  "format": "json",
         //                 "nojsoncallback": "1",
          //                "api_key": apiKey]
        
      //  for (key, value) in baseParams {
       //     let item = URLQueryItem(name: key, value: value)
        //    queryItems.append(item)
       // }
        
       // if let additionalParams = parameters {
        //    for (key, value) in additionalParams {
        //        let item = URLQueryItem(name: key, value: value)
         //       queryItems.append(item)
          //  }
      //  }
        //components.queryItems = queryItems
        print(components.url!)
        return components.url!
        
    }
}


