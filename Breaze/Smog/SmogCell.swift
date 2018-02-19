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
    @IBOutlet var parameterLabel: UILabel!
    @IBOutlet var AQILabel: UILabel!

    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        siteNameLabel.adjustsFontForContentSizeCategory = true
        parameterLabel.adjustsFontForContentSizeCategory = true
        AQILabel.adjustsFontForContentSizeCategory = true
    }
}
