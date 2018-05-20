//
//  HourlyForecastCell.swift
//  Breaze
//
//  Created by Joe Hardy on 5/6/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit

class HourlyForecastCell: UITableViewCell {
    
    @IBOutlet var tempLabel: UILabel!
    @IBOutlet var humidityLabel: UILabel!
    @IBOutlet var windSpeedLabel: UILabel!
    @IBOutlet var conditionsLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var iconImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        tempLabel.adjustsFontForContentSizeCategory = true
        humidityLabel.adjustsFontForContentSizeCategory = true
        conditionsLabel.adjustsFontForContentSizeCategory = true
        
    }
}
