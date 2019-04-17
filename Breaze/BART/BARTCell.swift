//
//  BARTCell.swift
//  Breaze
//
//  Created by Joe Hardy on 2/7/19.
//  Copyright © 2019 Carquinez. All rights reserved.
//

import UIKit

class BARTCell: UITableViewCell {
    
    @IBOutlet var numCarsLabel: UILabel!
    @IBOutlet var minToArrivalLabel: UILabel!
    @IBOutlet var destinationLabel: UILabel!
    @IBOutlet var lineColorLabel: UILabel!
    @IBOutlet var lineColorView: UIView!
    
    
    override func awakeFromNib() {
        //super.awakeFromNib()
        //numCarsLabel.text = "hello world"
        //highTempLabel.adjustsFontForContentSizeCategory = true
       // lowTempLabel.adjustsFontForContentSizeCategory = true
        //iconLabel.adjustsFontForContentSizeCategory = true
    }
}
