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
        case pendingRequest
        case pendingStream
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
    
    private let activityIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        return spinner
    }()
    
    // MARK: - Lifecycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

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
        contentView.addSubview(activityIndicator)
        
        self.accessoryType = .disclosureIndicator

        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: textLabel?.leadingAnchor ?? contentView.leadingAnchor, constant: 0),
            progressView.trailingAnchor.constraint(equalTo: percentageLabel.leadingAnchor, constant: -8),
            progressView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            percentageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            percentageLabel.centerYAnchor.constraint(equalTo: progressView.centerYAnchor),
            percentageLabel.widthAnchor.constraint(equalToConstant: 50),

            activityIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    // MARK: - Public Methods
    
    func setDownloadState(_ state: DownloadState) {
        reset()
        
        switch state {
        case .notDownloaded:
            accessoryType = .disclosureIndicator
            textLabel?.alpha = 1.0
            detailTextLabel?.alpha = 1.0
            
        case .pendingRequest, .pendingStream:
            print("ShowDetailTableViewCell: setDownloadState received .pendingStream or .pendingRequest. Starting spinner.")
            activityIndicator.startAnimating()
            accessoryType = .none
            textLabel?.alpha = 0.7
            detailTextLabel?.alpha = 0.7
            
        case .downloading(let progress):
            progressView.isHidden = false
            percentageLabel.isHidden = false
            progressView.progress = progress
            percentageLabel.text = "\(Int(progress * 100))%"
            percentageLabel.applyTextStyle(AppFonts.captionSecondary)
            accessoryType = .none
            textLabel?.alpha = 1.0
            detailTextLabel?.alpha = 1.0
            
        case .downloaded:
            accessoryType = .checkmark
            detailTextLabel?.text = "Downloaded"
            detailTextLabel?.applyTextStyle(AppFonts.captionSecondary)
            textLabel?.alpha = 1.0
            detailTextLabel?.alpha = 1.0
        }
    }
    
    private func reset() {
        progressView.isHidden = true
        percentageLabel.isHidden = true
        activityIndicator.stopAnimating()
        
        progressView.progress = 0
        percentageLabel.text = nil
        accessoryType = .disclosureIndicator
        textLabel?.alpha = 1.0
        detailTextLabel?.alpha = 1.0
        detailTextLabel?.text = nil
    }
}
