//
//  ModalPlayerTableViewCell.swift
//  Breaze
//
//  Created by Joseph Hardy on 8/2/20.
//  Copyright 2020 Carquinez. All rights reserved.
//

import UIKit

class ModalPlayerTableViewCell: UITableViewCell {

    // Called when the cell is created programmatically
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    // Called when the cell is loaded from a storyboard or XIB
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // awakeFromNib will be called after this, so commonInit() is called there
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }

    private func commonInit() {
        // Ensure the style allows for a textLabel if you're relying on the default one.
        // If you're using a custom style from a XIB without a textLabel outlet, this might be nil.
        textLabel?.applyTextStyle(AppFonts.bodyPrimary)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
