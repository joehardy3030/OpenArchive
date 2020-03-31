//
//  HourlyDetailView.swift
//  Breaze
//
//  Created by Joe Hardy on 5/20/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit

class HourlyDetailViewController: UIViewController {
    
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var conditionsLabel: UILabel!
    @IBOutlet var windLabel: UILabel!
    @IBOutlet var tempLabel: UILabel!
    @IBOutlet var UVILabel: UILabel!
    @IBOutlet var feelslikeLabel: UILabel!
    @IBOutlet var dewpointLabel: UILabel!
    @IBOutlet var MSLPLabel: UILabel!
    @IBOutlet var humidityLabel: UILabel!
    
    var hourForecast: WeatherModel?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let forecast = hourForecast else { return }
        
        if let utcTime = forecast.dt {
            let dateFormatter = DateFormatter()
            let date = Date(timeIntervalSince1970: Double(utcTime) )
            dateFormatter.dateFormat = "MMM dd, h:mm a"
            let localDate = dateFormatter.string(from: date)
            timeLabel.text = "Time: " + localDate
        }
        
        if let conditions = forecast.conditions {
            conditionsLabel.text = "Conditions: " + conditions
        }

        if let wind_dir = Utils.windDirName(num: forecast.wind_dir), let wind_speed = forecast.wind_speed {
            windLabel.text = "Wind: " + wind_dir + " " + String(format:"%.0f", wind_speed) + "MPH"
        }
 
        if let temp = forecast.temp {
            tempLabel.text = "Temp: " + String(format:"%.0f", temp) + " F"
        }
        
        if let avehumidity = forecast.avehumidity {
            humidityLabel.text = "Humidity: " + String(format:"%.0f", avehumidity) + "%"
        }
    }
}
