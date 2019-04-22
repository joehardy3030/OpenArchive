//
//  BARTStation.swift
//  Breaze
//
//  Created by Joe Hardy on 4/21/19.
//  Copyright © 2019 Carquinez. All rights reserved.
//

import UIKit

class BARTStation: NSObject {
    
    var abbreviation: String
    var direction: String
    
    init(abbreviation: String,
         direction: String
        ) {
        self.abbreviation = abbreviation
        self.direction = direction
        
        super.init()
    }
}
