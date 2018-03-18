//
//  SmogStore.swift
//  Breaze
//
//  Created by Joseph Hardy on 2/10/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//


import UIKit

enum SmogForecastResult {
    case success([SmogDay])
   // case success([SmogReading])
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
    
    func fetchSmogForecast(completion: @escaping (SmogForecastResult) -> Void) {
        
        let url = AirNowAPI.smogForecastURL
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result = self.processSmogForecastResult(data: data, error: error)
            completion(result)
            print(result)
        }
        task.resume()
     }
    
}

