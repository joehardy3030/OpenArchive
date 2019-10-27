//
//  WeatherModel.swift
//  Breaze
//
//  Created by Joe Hardy on 10/26/19.
//  Copyright © 2019 Carquinez. All rights reserved.
//

import UIKit

struct WeatherModel: Codable {
    let temp: Double?
    let high: Double?
    let low: Double?
    let icon: String?
    let icon_url: String?
    let main_description: String?
    let conditions: String?
    let avehumidity: Double?
    let weekday_short: String?
    
    var dictionary: [String : Any]? {
        return ["temp": temp as Any,
                "high": high as Any,
                "low": low as Any,
                "icon": icon as Any,
                "icon_url": icon_url as Any,
                "main_description": main_description as Any,
                "conidtions": conditions as Any,
                "avehumidity": avehumidity as Any,
                "weekday_short": weekday_short as Any]
    }

    init(temp: Double?,
         high: Double?,
         low: Double?,
         icon: String?,
         icon_url: String?,
         main_description: String?,
         conditions: String?,
         avehumidity: Double?,
         weekday_short: String?)
    {
        self.temp = temp
        self.high = high
        self.low = low
        self.icon = icon
        self.icon_url = icon_url
        self.main_description = main_description
        self.conditions = conditions
        self.avehumidity = avehumidity
        self.weekday_short = weekday_short
        
    }
    
}
