//
//  WeatherStore.swift
//  Breaze
//
//  Created by Joseph Hardy on 2/3/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit

enum HourlyForecastResult {
    case success([HourlyForecastHour], String)
    case failure(Error)
}

enum SimpleForecastResult {
    case success([SimpleForecastDay], String)
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
            let result = self.processSimpleForecastResult(data: data, error: error)
            completion(result)
        }
        task.resume()
    }
    
    func fetchHourlyForecast(completion: @escaping (HourlyForecastResult) -> Void)  {
        
        let url = WundergroundAPI.hourlyForecastURL
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result = self.processHourlyForecastResult(data: data, error: error)
            completion(result)
        }
        task.resume()
    }

    func fetchLocalHourlyForecast(parameters: [String:String]?, completion: @escaping (HourlyForecastResult) -> Void)  {
        
        let url = WundergroundAPI.localHourlyForecastURL(paramaters: parameters)
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result = self.processHourlyForecastResult(data: data, error: error)
            completion(result)
        }
        task.resume()
    }

    func fetchLocalSimpleForecast(parameters: [String:String]?, completion: @escaping (SimpleForecastResult) -> Void) {
        
        let url = WundergroundAPI.localSimpleForecastURL(paramaters: parameters)
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result = self.processSimpleForecastResult(data: data, error: error)
            completion(result)
        }
        task.resume()
    }

}
