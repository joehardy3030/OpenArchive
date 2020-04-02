//
//  SmogDay.swift
//  Breaze
//
//  Created by Joseph Hardy on 3/11/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit

class SmogDay: NSObject {
    
    var SO2: Int?
    var NO2: Int?
    var ozone: Int?
    var PM25: Int?
    var siteName: String?
    
    init(SO2: Int?,
         NO2: Int?,
         ozone: Int?,
         PM25: Int?,
         siteName: String?) {
        self.SO2 = SO2
        self.NO2 = NO2
        self.ozone = ozone
        self.PM25 = PM25
        self.siteName = siteName
        
        super.init()
    }
}
