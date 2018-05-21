//
//  HourlyForecastHour.swift
//  Breaze
//
//  Created by Joseph Hardy on 2/5/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import Foundation

import UIKit

class HourlyForecastHour: NSObject {
    
    let temp: String
    let feelslike: String
    let dewpoint: String
    let mslp: String
    let wspd: String
    let dir: String
    let icon: String
    let wx: String
    let uvi: String
    let humidity: String
    let civil: String
    
    init(temp: String,
         feelslike: String,
         dewpoint: String,
         mslp: String,
         wspd: String,
         dir: String,
         icon: String,
         wx: String,
         uvi: String,
         humidity: String,
         civil: String)
    {
        self.temp = temp
        self.feelslike = feelslike
        self.dewpoint = dewpoint
        self.mslp = mslp
        self.wspd = wspd
        self.dir = dir
        self.icon = icon
        self.wx = wx
        self.uvi = uvi
        self.humidity = humidity
        self.civil = civil
        
        super.init()
    }
}
