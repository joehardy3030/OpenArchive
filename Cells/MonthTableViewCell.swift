//
//  MonthTableViewCell.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/2/20.
//  Copyright 2020 Carquinez. All rights reserved.
//

import UIKit

class MonthTableViewCell: UITableViewCell {
    
    // MARK: - UI Elements
    
    // Keep this IBOutlet for Interface Builder compatibility
    @IBOutlet weak var monthLabel: UILabel? {
        didSet {
            if let label = monthLabel {
                label.font = AppFonts.title
            }
        }
    }
    
    // Private label for programmatic creation (only used when IBOutlet is nil)
    private var programmaticMonthLabel: UILabel?
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        print("Warning: MonthTableViewCell initialized from Interface Builder. Programmatic setup will be applied.")
        // Let Interface Builder connect outlets
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Apply additional setup for Interface Builder initialized cells
        // We don't call setupUI() here to avoid duplicate UI elements
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Only set up programmatic UI if not using Interface Builder
        if monthLabel == nil {
            let label = UILabel()
            label.font = AppFonts.title
            label.translatesAutoresizingMaskIntoConstraints = false
            programmaticMonthLabel = label
            
            contentView.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
                label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
            ])
        }
        
        backgroundColor = UIColor.systemGray6
    }
    
    // MARK: - Configuration
    func configure(with month: String) {
        if let ibLabel = monthLabel {
            ibLabel.text = month
        } else if let programmaticLabel = programmaticMonthLabel {
            programmaticLabel.text = month
        }
    }
}
