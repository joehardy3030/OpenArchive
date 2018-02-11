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
        return AQSAPI.smogForecast(fromJSON: jsonData)
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
        
        let url = AQSAPI.smogForecastURL
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

