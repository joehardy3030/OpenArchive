//
//  Weather.swift
//  Breaze
//
//  Created by Joseph Hardy on 2/5/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit

class SimpleForecastDay: NSObject {

    let high: String
    let low: String
    let icon: String
    let icon_url: String
    let conditions: String
    let avehumidity: Int
    
    init(high: String,
         low: String,
         icon: String,
         icon_url: String,
         conditions: String,
         avehumidity: Int) {
        self.high = high
        self.low = low
        self.icon = icon
        self.icon_url = icon_url
        self.conditions = conditions
        self.avehumidity = avehumidity
        
        super.init()            
    }
}
