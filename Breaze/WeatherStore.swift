//
//  WeatherStore.swift
//  Breaze
//
//  Created by Joseph Hardy on 2/3/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import Foundation

class WeatherStore {
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    func fetchInterestingPhotos() {
        
        let url = WundergroundAPI.simpleForecastURL
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            if let jsonData = data {
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print(jsonString)
                }
            }
            else if let requestError = error {
                print("Error fetching interesting photos: \(requestError)")
            }
            else {
                print("Unexpected error with the request")
            }
        }
        task.resume()
    }
}
