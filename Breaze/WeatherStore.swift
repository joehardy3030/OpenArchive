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
    
    func fetchSimpleForecast() {
        
        let url = WundergroundAPI.simpleForecastURL
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            if let jsonData = data {
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print(jsonString)
                }
            }
            else if let requestError = error {
                print("Error fetching simple forecast: \(requestError)")
            }
            else {
                print("Unexpected error with the request")
            }
        }
        task.resume()
    }
    
    func fetchHourlyForecast() {
        
        let url = WundergroundAPI.hourlyForecastURL
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            if let jsonData = data {
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print(jsonString)
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
