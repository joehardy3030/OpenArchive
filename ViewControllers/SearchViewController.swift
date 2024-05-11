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
    let minRatingTextField = UITextField()
    let venueTextField = UITextField()
    let searchButton = UIButton()
    var searchTermsModel = SearchTermsModel()
    // var showMetadatas: ShowMetadatas?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        
        // Configure text fields with borders
        songTextField.placeholder = "Enter search term"
        songTextField.borderStyle = .roundedRect
        //startDateTextField.placeholder = "Start Date (YYYY-MM-DD)"
        venueTextField.placeholder = "Venue"
        venueTextField.borderStyle = .roundedRect
        startDateTextField.placeholder = "Start Year (YYYY)"
        startDateTextField.borderStyle = .roundedRect
        //endDateTextField.placeholder = "End Date (YYYY-MM-DD)"
        endDateTextField.placeholder = "End Year (YYYY)"
        endDateTextField.borderStyle = .roundedRect
        minRatingTextField.placeholder = "1-5 stars min"
        minRatingTextField.borderStyle = .roundedRect
        
        // Configure button
        searchButton.setTitle("Search", for: .normal)
        searchButton.backgroundColor = .blue
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        
        // Layout your views
        songLabel.frame = CGRect(x: 20, y: 80, width: 200, height: 20)
        songTextField.frame = CGRect(x: 20, y: 100, width: 200, height: 40)
        venueTextField.frame = CGRect(x: 20, y: 150, width: 200, height: 40) // New
        startDateTextField.frame = CGRect(x: 20, y: 200, width: 200, height: 40) // New
        endDateTextField.frame = CGRect(x: 20, y: 250, width: 200, height: 40) // New
        minRatingTextField.frame = CGRect(x: 20, y: 300, width: 200, height: 40) // New
        searchButton.frame = CGRect(x: 20, y: 350, width: 200, height: 40)
        
        // Add subviews
        view.addSubview(songLabel)
        view.addSubview(songTextField)
        view.addSubview(venueTextField)
        view.addSubview(startDateTextField)
        view.addSubview(endDateTextField)
        view.addSubview(minRatingTextField)
        view.addSubview(searchButton)
        
        // Dismiss keyboard when tapping outside the text boxes
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func searchButtonTapped() {
        
        self.searchTermsModel.venue = venueTextField.text
        if let sy = startDateTextField.text {
            self.searchTermsModel.startYear = sy
        }
        if let ey = endDateTextField.text {
            self.searchTermsModel.endYear = ey
        }
        self.searchTermsModel.searchTerm = songTextField.text
        self.searchTermsModel.minRating = minRatingTextField.text
        view.endEditing(true)
        performSegue(withIdentifier: "showSearchResults", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSearchResults" {
            print("showSearchResults Segue")
            if let target = segue.destination as? ShowsListViewController {
                target.db = db
                target.resetMonth()
                target.getIASearchTerm(searchTermsModel: self.searchTermsModel)
            }
        }
    }
}
