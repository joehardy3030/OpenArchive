//
//  ShowDetailTableViewCell.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/25/20.
//  Copyright 2020 Carquinez. All rights reserved.
//

import UIKit

class ShowDetailTableViewCell: UITableViewCell {
    
    enum DownloadState {
        case notDownloaded
        case downloading(progress: Float)
        case downloaded
    }
    
    // MARK: - Properties
    
    private let progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .default)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.tintColor = .systemBlue
        view.trackTintColor = UIColor.systemGray.withAlphaComponent(0.3)
        view.isHidden = true
        return view
    }()
    
    private let percentageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .right
        label.isHidden = true
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        reset()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        contentView.addSubview(progressView)
        contentView.addSubview(percentageLabel)
        
        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -80),
            progressView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            progressView.heightAnchor.constraint(equalToConstant: 2),
            
            percentageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            percentageLabel.centerYAnchor.constraint(equalTo: progressView.centerYAnchor),
            percentageLabel.widthAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Public Methods
    
    func setDownloadState(_ state: DownloadState) {
        reset()
        
        switch state {
        case .notDownloaded:
            // Just show the regular cell, no progress components
            break
            
        case .downloading(let progress):
            progressView.isHidden = false
            percentageLabel.isHidden = false
            progressView.progress = progress
            percentageLabel.text = "\(Int(progress * 100))%"
            percentageLabel.applyTextStyle(AppFonts.captionSecondary)
            accessoryType = .none
            
        case .downloaded:
            accessoryType = .checkmark
            detailTextLabel?.text = "Downloaded"
            detailTextLabel?.applyTextStyle(AppFonts.captionSecondary)
        }
    }
    
    private func reset() {
        progressView.isHidden = true
        percentageLabel.isHidden = true
        progressView.progress = 0
        percentageLabel.text = nil
        accessoryType = .none
        detailTextLabel?.text = nil
    }
}
