//
//  ShowDetailTableViewCell.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/25/20.
//  Copyright 2020 Carquinez. All rights reserved.
//

import UIKit

class ShowDetailTableViewCell: UITableViewCell {
    
    // MARK: - UI Elements
    
    // Keep these IBOutlets for Interface Builder compatibility
    @IBOutlet weak var detailTitleLabel: UILabel? {
        didSet {
            if let label = detailTitleLabel {
                label.font = AppFonts.subtitle
                label.numberOfLines = 0
            }
        }
    }
    
    @IBOutlet weak var detailContentLabel: UILabel? {
        didSet {
            if let label = detailContentLabel {
                label.font = AppFonts.body
                label.textColor = .secondaryLabel
                label.numberOfLines = 0
            }
        }
    }
    
    // Private labels for programmatic creation
    private var programmaticTitleLabel: UILabel?
    private var programmaticContentLabel: UILabel?
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        print("Warning: ShowDetailTableViewCell initialized from Interface Builder. Programmatic setup will be applied.")
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
        if detailTitleLabel == nil && detailContentLabel == nil {
            let titleLabel = UILabel()
            titleLabel.font = AppFonts.subtitle
            titleLabel.numberOfLines = 0
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            programmaticTitleLabel = titleLabel
            
            let contentLabel = UILabel()
            contentLabel.font = AppFonts.body
            contentLabel.textColor = .secondaryLabel
            contentLabel.numberOfLines = 0
            contentLabel.translatesAutoresizingMaskIntoConstraints = false
            programmaticContentLabel = contentLabel
            
            contentView.addSubview(titleLabel)
            contentView.addSubview(contentLabel)
            
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
                titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                
                contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                contentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
            ])
        }
    }
    
    // MARK: - Configuration
    func configure(title: String, content: String?) {
        // Update title label
        if let ibLabel = detailTitleLabel {
            ibLabel.text = title
        } else if let programmaticLabel = programmaticTitleLabel {
            programmaticLabel.text = title
        }
        
        // Update content label
        if let ibLabel = detailContentLabel {
            ibLabel.text = content
        } else if let programmaticLabel = programmaticContentLabel {
            programmaticLabel.text = content
        }
    }
}
