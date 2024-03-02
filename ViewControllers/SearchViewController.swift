//
//  SearchViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 2/3/24.
//  Copyright © 2024 Carquinez. All rights reserved.
//
import UIKit

class SearchViewController: ArchiveSuperViewController {

     let songLabel = UILabel()
     let songTextField = UITextField()
     let startDateTextField = UITextField()
     let endDateTextField = UITextField()
     let searchButton = UIButton()
     var showMetadatas: ShowMetadatas?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
 
        // Configure text fields with borders
        songTextField.placeholder = "Enter title name"
        songTextField.borderStyle = .roundedRect
        startDateTextField.placeholder = "Start Date (YYYY-MM-DD)"
        startDateTextField.borderStyle = .roundedRect
        endDateTextField.placeholder = "End Date (YYYY-MM-DD)"
        endDateTextField.borderStyle = .roundedRect
        
        // Configure button
        searchButton.setTitle("Search", for: .normal)
        searchButton.backgroundColor = .blue
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        
        // Layout your views
        songLabel.frame = CGRect(x: 20, y: 80, width: 200, height: 20)
        songTextField.frame = CGRect(x: 20, y: 100, width: 200, height: 40)
        startDateTextField.frame = CGRect(x: 20, y: 150, width: 200, height: 40) // New
        endDateTextField.frame = CGRect(x: 20, y: 200, width: 200, height: 40) // New
        searchButton.frame = CGRect(x: 20, y: 250, width: 200, height: 40)
        
        // Add subviews
        view.addSubview(songLabel)
        view.addSubview(songTextField)
        view.addSubview(startDateTextField)
        view.addSubview(endDateTextField)
        view.addSubview(searchButton)
    }
    
    @objc func searchButtonTapped() {
        getIASearchTerm()
    }
    
    func getIASearchTerm() {
        let searchTerm = songTextField.text ?? ""
        let startDate = startDateTextField.text ?? ""
        let endDate = endDateTextField.text ?? ""
        // Construct search URL with date range, assuming your API supports it
        let url = archiveAPI.searchTermURL(searchTerm: searchTerm, startDate: startDate, endDate: endDate)
        // print(url)
        archiveAPI.getIARequestItemsDecodable(url: url) {
            (response: ShowMetadatas?) -> Void in
             DispatchQueue.main.async{
                if let r = response {
                    self.showMetadatas = r
                }
            }
        }
    }
}
