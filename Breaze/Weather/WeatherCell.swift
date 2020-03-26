//
//  WeatherCell.swift
//  Breaze
//
//  Created by Joseph Hardy on 2/18/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit

class WeatherCell: UITableViewCell {
     
    @IBOutlet var currentTempLabel: UILabel!
    @IBOutlet var humidityLabel: UILabel!
    @IBOutlet var dayLabel: UILabel!
    @IBOutlet var iconLabel: UILabel!
    @IBOutlet var iconImage: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        currentTempLabel.adjustsFontForContentSizeCategory = true
        humidityLabel.adjustsFontForContentSizeCategory = true
        iconLabel.adjustsFontForContentSizeCategory = true
    }
}
