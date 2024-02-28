//
//  SearchViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 2/3/24.
//  Copyright © 2024 Carquinez. All rights reserved.
//
import UIKit

class SearchViewController: ArchiveSuperViewController {
    
    let artistLabel = UILabel()
    let artistTextField = UITextField()
    let titleLabel = UILabel()
    let titleTextField = UITextField()
    let searchButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
    }
    
    private func setupUI() {
        // Configure labels
        artistLabel.text = "Artist"
        titleLabel.text = "Title"
        
        // Configure text fields with borders
        artistTextField.placeholder = "Enter artist name"
        artistTextField.borderStyle = .roundedRect
        titleTextField.placeholder = "Enter title name"
        titleTextField.borderStyle = .roundedRect
        
        // Configure button
        searchButton.setTitle("Search", for: .normal)
        searchButton.backgroundColor = .blue
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        
        // Layout your views properly here. This is just a simple setup.
        artistLabel.frame = CGRect(x: 20, y: 80, width: 200, height: 20)
        artistTextField.frame = CGRect(x: 20, y: 100, width: 200, height: 40)
        titleLabel.frame = CGRect(x: 20, y: 150, width: 200, height: 20)
        titleTextField.frame = CGRect(x: 20, y: 170, width: 200, height: 40)
        searchButton.frame = CGRect(x: 20, y: 220, width: 200, height: 40)
        
        // Add subviews
        view.addSubview(artistLabel)
        view.addSubview(artistTextField)
        view.addSubview(titleLabel)
        view.addSubview(titleTextField)
        view.addSubview(searchButton)
    }
    
    @objc func searchButtonTapped() {
        // Implement search functionality here
        // https://archive.org/search?query=Black+throated+wind
        // ArchiveAPI.getIARequestItemsDecodable(url: String, completion: @escaping (ShowMetadatas?) -> Void) {

        print("Search with Artist: \(artistTextField.text ?? "") Title: \(titleTextField.text ?? "")")
        // Close the modal
        // dismiss(animated: true, completion: nil)
    }
}
