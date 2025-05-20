//
//  ShowsListTableViewCell.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/4/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit

class ShowsListTableViewCell: UITableViewCell {
    // MARK: - UI Elements
    private let collectionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        //label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let venueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        //label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let transfererLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let sourceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let starsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
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
    }
    
    // MARK: - Configuration
    private func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
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
