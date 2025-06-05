//  ModalPlayerTableViewCell.swift
//  Breaze
//
//  Created by Joseph Hardy on 8/2/20.
//  Copyright 2020 Carquinez. All rights reserved.
//

import UIKit

class ModalPlayerTableViewCell: UITableViewCell {
    
    // MARK: - UI Elements
    
    // Keep these IBOutlets for Interface Builder compatibility
    @IBOutlet weak var songTitleLabel: UILabel? {
        didSet {
            if let label = songTitleLabel {
                label.font = AppFonts.subtitle
                label.numberOfLines = 1
            }
        }
    }
    
    @IBOutlet weak var durationLabel: UILabel? {
        didSet {
            if let label = durationLabel {
                label.font = AppFonts.monospaced
                label.textColor = .secondaryLabel
                label.textAlignment = .right
                
                // Set width constraint with high priority (999) instead of required
                // to avoid layout conflicts with the pull indicator
                if let widthConstraint = label.constraints.first(where: { $0.firstAttribute == .width }) {
                    widthConstraint.priority = .init(999)
                }
            }
        }
    }
    
    // Private labels for programmatic creation
    private var programmaticSongTitleLabel: UILabel?
    private var programmaticDurationLabel: UILabel?
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        print("Warning: ModalPlayerTableViewCell initialized from Interface Builder. Programmatic setup will be applied.")
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
        if songTitleLabel == nil && durationLabel == nil {
            let titleLabel = UILabel()
            titleLabel.font = AppFonts.subtitle
            titleLabel.numberOfLines = 1
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            programmaticSongTitleLabel = titleLabel
            
            let timeLabel = UILabel()
            timeLabel.font = AppFonts.monospaced
            timeLabel.textColor = .secondaryLabel
            timeLabel.textAlignment = .right
            timeLabel.translatesAutoresizingMaskIntoConstraints = false
            programmaticDurationLabel = timeLabel
            
            contentView.addSubview(titleLabel)
            contentView.addSubview(timeLabel)
            
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
                titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
                
                timeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                timeLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
                timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            ])
            
            // Create width constraint with high priority (999) instead of required
            // to avoid layout conflicts with the pull indicator and other UI elements
            let widthConstraint = timeLabel.widthAnchor.constraint(equalToConstant: 60)
            widthConstraint.priority = .init(999)
            widthConstraint.isActive = true
            
            titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            timeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        }
    }
    
    // MARK: - Configuration
    func configure(with songTitle: String, duration: String?) {
        // Update title label
        if let ibLabel = songTitleLabel {
            ibLabel.text = songTitle
        } else if let programmaticLabel = programmaticSongTitleLabel {
            programmaticLabel.text = songTitle
        }
        
        // Update duration label
        if let ibLabel = durationLabel {
            ibLabel.text = duration
        } else if let programmaticLabel = programmaticDurationLabel {
            programmaticLabel.text = duration
        }
    }
}
