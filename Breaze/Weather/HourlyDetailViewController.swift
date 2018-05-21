//
//  HourlyDetailView.swift
//  Breaze
//
//  Created by Joe Hardy on 5/20/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit

class HourlyDetailViewController: UIViewController {
    
    @IBOutlet var inputField: UITextField!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var conditionsLabel: UILabel!
    @IBOutlet var tempLabel: UILabel!
    @IBOutlet var wspdLabel: UILabel!
    @IBOutlet var wdirLabel: UILabel!
    @IBOutlet var UVILabel: UILabel!
    
    var hourlyForecastHour: HourlyForecastHour!
    var utils = Utils()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        timeLabel.text = hourlyForecastHour.civil
        conditionsLabel.text = utils.switchConditionsText(icon: hourlyForecastHour.icon)
        tempLabel.text = hourlyForecastHour.temp
        wspdLabel.text = hourlyForecastHour.wspd
        wdirLabel.text = hourlyForecastHour.dir
        UVILabel.text = hourlyForecastHour.uvi
    }
}
