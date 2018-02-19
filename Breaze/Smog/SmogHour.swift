//
//  SmogHour.swift
//  Breaze
//
//  Created by Joseph Hardy on 2/10/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit

class SmogHour: NSObject {
    
    let ppm25: String
    let ozone: String
    
    init(ppm25: String,
         ozone: String) {
        self.ppm25 = ppm25
        self.ozone = ozone
        
        super.init()
    }
}

