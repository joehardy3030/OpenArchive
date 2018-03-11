//
//  SmogDay.swift
//  Breaze
//
//  Created by Joseph Hardy on 3/11/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit

class SmogDay: NSObject {
    
    let parameter: String
    let AQI: Int
    let siteName: String
    
    init(parameter: String,
         AQI: Int,
         siteName: String) {
        self.parameter = parameter
        self.AQI = AQI
        self.siteName = siteName
        
        super.init()
    }
}
