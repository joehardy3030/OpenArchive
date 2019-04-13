//
//  BARTResult.swift
//  Breaze
//
//  Created by Joe Hardy on 2/10/19.
//  Copyright © 2019 Carquinez. All rights reserved.
//

import UIKit

class BARTReading: NSObject {
    
    var numCars: String
    var minToArrival: String
    var lineColor: String
    
    init(numCars: String,
         minToArrival: String,
         lineColor: String
         ) {
        self.numCars = numCars
        self.minToArrival = minToArrival
        self.lineColor = lineColor
        
        super.init()
    }
}
