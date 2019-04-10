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
    
    init(numCars: String,
         minToArrival: String
         ) {
        self.numCars = numCars
        self.minToArrival = minToArrival
        
        super.init()
    }
}
