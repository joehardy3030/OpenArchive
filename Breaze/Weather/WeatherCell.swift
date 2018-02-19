//
//  WeatherCell.swift
//  Breaze
//
//  Created by Joseph Hardy on 2/18/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit

class WeatherCell: UITableViewCell {
    
    @IBOutlet var highTempLabel: UILabel!
    @IBOutlet var lowTempLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        highTempLabel.adjustsFontForContentSizeCategory = true
        lowTempLabel.adjustsFontForContentSizeCategory = true
    }
}
