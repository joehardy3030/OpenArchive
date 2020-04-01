//
//  SmogCell.swift
//  Breaze
//
//  Created by Joseph Hardy on 2/18/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit

class SmogCell: UITableViewCell {
    
    @IBOutlet var siteNameLabel: UILabel!
    @IBOutlet var PM25Label: UILabel!
    @IBOutlet var ozoneLabel: UILabel!
    @IBOutlet var NO2Label: UILabel!
    @IBOutlet var SO2Label: UILabel! 
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        siteNameLabel.adjustsFontForContentSizeCategory = true
    }
}
