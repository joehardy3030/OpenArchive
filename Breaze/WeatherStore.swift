//
//  WeatherStore.swift
//  Breaze
//
//  Created by Joseph Hardy on 2/3/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import Foundation

enum HourlyForecastResult {
    case success([HourlyForecastHour])
    case failure(Error)
}

enum SimpleForecastResult {
    case success([SimpleForecastDay])
    case failure(Error)
}

class WeatherStore {
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    private func processSimpleForecastResult(data: Data?, error: Error?) -> SimpleForecastResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        return WundergroundAPI.simpleForecast(fromJSON: jsonData)
    }

    private func processHourlyForecastResult(data: Data?, error: Error?) -> HourlyForecastResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        return WundergroundAPI.hourlyForecast(fromJSON: jsonData)
    }

    func fetchSimpleForecast(completion: @escaping (SimpleForecastResult) -> Void) {
        
        let url = WundergroundAPI.simpleForecastURL
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
//            if let jsonData = data {
//                do {
 //                   let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
  //                  print(jsonObject)
   //             }
    //            catch let error {
     //               print("Error creating JSON object: \(error)")
      //          }
       //     }
        //    else if let requestError = error {
         //       print("Error fetching simple forecast: \(requestError)")
          //  }
        //    else {
        //        print("Unexpected error with the request")
        //    }
       // }
            let result = self.processSimpleForecastResult(data: data, error: error)
            completion(result)
        }
        task.resume()
    }
    
    func fetchHourlyForecast() {
        
        let url = WundergroundAPI.hourlyForecastURL
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            if let jsonData = data {
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
                    print(jsonObject)
                }
                catch let error {
                    print("Error creating JSON object: \(error)")
                }
            }
            else if let requestError = error {
                print("Error fetching hourly forecast: \(requestError)")
            }
            else {
                print("Unexpected error with the request")
            }
        }
        task.resume()
    }
}
