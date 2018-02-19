//
//  SmogReading.swift
//  Breaze
//
//  Created by Joseph Hardy on 2/16/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit

class SmogReading: NSObject {
    
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
