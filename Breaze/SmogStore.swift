//
//  SmogStore.swift
//  Breaze
//
//  Created by Joseph Hardy on 2/10/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//


import UIKit

enum SmogForecastResult {
    case success([SmogHour])
    case failure(Error)
}

class SmogStore {
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    private func processSmogForecastResult(data: Data?, error: Error?) -> SmogForecastResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        return AirNowAPI.smogForecast(fromJSON: jsonData)
    }
    
 //   func fetchSmogForecast(completion: @escaping (SmogResult) -> Void) {
        
 //       let url = AQSAPI.smogForecastURL
 //       let request = URLRequest(url: url)
 //       let task = session.dataTask(with: request) { (data, response, error) -> Void in
 //           let result = self.processSmogForecastResult(data: data, error: error)
 //           completion(result)
 //       }
 //       task.resume()
 //   }
    
    func fetchSmogForecast() {
        
        let url = AirNowAPI.smogForecastURL
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            if let stringData = data {
                let stringObject = String(data: stringData, encoding: .utf8)
                    //print(jsonObject
                    print(stringObject!)
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

