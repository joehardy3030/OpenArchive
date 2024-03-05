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
     let searchButton = UIButton()
     var startYear = "1965"
     var endYear = "1995"
    var minRating: String?
    var searchTerm: String?
     var showMetadatas: ShowMetadatas?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
 
        // Configure text fields with borders
        songTextField.placeholder = "Enter search term"
        songTextField.borderStyle = .roundedRect
        minRatingTextField.placeholder = "1-5 stars min"
        minRatingTextField.borderStyle = .roundedRect
        //startDateTextField.placeholder = "Start Date (YYYY-MM-DD)"
        startDateTextField.placeholder = "Start Year (YYYY)"
        startDateTextField.borderStyle = .roundedRect
        //endDateTextField.placeholder = "End Date (YYYY-MM-DD)"
        endDateTextField.placeholder = "End Year (YYYY)"
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
        minRatingTextField.frame = CGRect(x: 20, y: 250, width: 200, height: 40) // New
        searchButton.frame = CGRect(x: 20, y: 300, width: 200, height: 40)
        
        // Add subviews
        view.addSubview(songLabel)
        view.addSubview(songTextField)
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
        if let sy = startDateTextField.text {
            self.startYear = sy
        }
        if let ey = endDateTextField.text {
            self.endYear = ey
        }
        self.searchTerm = songTextField.text
        self.minRating = minRatingTextField.text
        view.endEditing(true)
        performSegue(withIdentifier: "showSearchResults", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSearchResults" {
            print("showSearchResults Segue")
            if let target = segue.destination as? ShowsListViewController {
                target.startYear = self.startYear
                target.endYear = self.endYear
                target.searchTerm = self.searchTerm
                target.minRating = self.minRating
                target.sbdOnly = true
                target.resetMonth()
                target.db = db
                target.getIASearchTerm()
            }
        }
    }
}
