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
    
    var hourlyForecastHour: HourlyForecastHour!
    var utils = Utils()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        timeLabel.text = "Time: " + hourlyForecastHour.civil
        conditionsLabel.text = "Conditions: " + utils.switchConditionsText(icon: hourlyForecastHour.icon)
        tempLabel.text = "Temperature: " + hourlyForecastHour.temp + " F"
        windLabel.text = "Wind: " + hourlyForecastHour.dir + " " + hourlyForecastHour.wspd + " MPH"
        UVILabel.text = "UVI: " + hourlyForecastHour.uvi
        feelslikeLabel.text = "Feels like: " + hourlyForecastHour.feelslike + " F"
        dewpointLabel.text = "Dewpoint: " + hourlyForecastHour.dewpoint + " F"
        MSLPLabel.text = "MSLP: " + hourlyForecastHour.mslp + " inHg"
    }
}
