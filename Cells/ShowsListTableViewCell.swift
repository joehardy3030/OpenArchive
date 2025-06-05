//
//  ShowsListTableViewCell.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/4/20.
//  Copyright 2020 Carquinez. All rights reserved.
//

import UIKit

class ShowsListTableViewCell: UITableViewCell {
    // MARK: - UI Elements
    public let collectionLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.title
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    public let dateLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.subtitle
        //label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    public let venueLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.body
        label.textColor = .secondaryLabel
        //label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    public let transfererLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.bodySecondary
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    public let sourceLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.bodySecondary
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    public let starsLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.body
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        contentView.addSubview(collectionLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(venueLabel)
        contentView.addSubview(transfererLabel)
        contentView.addSubview(sourceLabel)
        contentView.addSubview(starsLabel)
        
        NSLayoutConstraint.activate([
            // Collection Label (Band Name)
            collectionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            collectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            collectionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Date Label
            dateLabel.topAnchor.constraint(equalTo: collectionLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Venue Label
            venueLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            venueLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            venueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Transferer Label
            transfererLabel.topAnchor.constraint(equalTo: venueLabel.bottomAnchor, constant: 4),
            transfererLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            transfererLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Source Label
            sourceLabel.topAnchor.constraint(equalTo: transfererLabel.bottomAnchor, constant: 4),
            sourceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sourceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Stars Label
            starsLabel.topAnchor.constraint(equalTo: sourceLabel.bottomAnchor, constant: 4),
            starsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            starsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            starsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        // Set content hugging and compression resistance priorities
        collectionLabel.setContentHuggingPriority(.required, for: .vertical)
        collectionLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        dateLabel.setContentHuggingPriority(.required, for: .vertical)
        dateLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        venueLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        venueLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        transfererLabel.setContentHuggingPriority(.required, for: .vertical)
        transfererLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        sourceLabel.setContentHuggingPriority(.required, for: .vertical)
        sourceLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        starsLabel.setContentHuggingPriority(.required, for: .vertical)
        starsLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    
    // MARK: - Configuration
    private func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)  // Use UTC
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.string(from: date)
        }
        return dateString
    }
    
    func configure(with show: ShowMetadata) {
        if let creator = show.creator {
            collectionLabel.text = creator
        } else if let collections = show.collection {
            collectionLabel.text = collections.joined(separator: ", ")
        } else {
            collectionLabel.text = ""
        }
        
        dateLabel.text = formatDate(show.date)
        
        if let venue = show.venue, let coverage = show.coverage {
            venueLabel.text = "\(venue), \(coverage)"
        } else {
            venueLabel.text = show.venue
        }
        transfererLabel.text = show.transferer
        sourceLabel.text = show.source
        
        if let rating = show.avg_rating, let reviews = show.num_reviews {
            starsLabel.text = "\(rating) stars \(reviews) ratings"
        } else {
            starsLabel.text = ""
        }
    }
    
    func configure(with showModel: ShowMetadataModel) {
        guard let metadata = showModel.metadata else { return }
        
        if let creator = metadata.creator {
            collectionLabel.text = creator
        } else if let collections = metadata.collection {
            collectionLabel.text = collections.joined(separator: ", ")
        } else {
            collectionLabel.text = ""
        }
        
        dateLabel.text = formatDate(metadata.date)
        
        if let venue = metadata.venue, let coverage = metadata.coverage {
            venueLabel.text = "\(venue), \(coverage)"
        } else {
            venueLabel.text = metadata.venue
        }
        transfererLabel.text = metadata.transferer
        sourceLabel.text = metadata.source
        
        if let rating = metadata.avg_rating, let reviews = metadata.num_reviews {
            starsLabel.text = "\(rating) stars \(reviews) ratings"
        } else {
            starsLabel.text = ""
        }
    }
}
