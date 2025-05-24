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
    let collectionPicker = UIPickerView()
    let collectionTextField = UITextField()
    var searchTermsModel = SearchTermsModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionPicker()
    }
    
    private func setupCollectionPicker() {
        collectionPicker.delegate = self
        collectionPicker.dataSource = self
        
        // Configure collection text field
        collectionTextField.placeholder = "Select Collection"
        collectionTextField.borderStyle = .roundedRect
        collectionTextField.inputView = collectionPicker
        
        // Add toolbar with Done button
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44))
        toolbar.barStyle = .default
        toolbar.isTranslucent = true
        toolbar.sizeToFit()
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(donePicker))
        
        toolbar.items = [flexSpace, doneButton]
        toolbar.isUserInteractionEnabled = true
        
        collectionTextField.inputAccessoryView = toolbar
        collectionTextField.text = CollectionConfig.collectionsText[0] // Set default value
    }
    
    @objc func donePicker() {
        view.endEditing(true)
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
        collectionTextField.frame = CGRect(x: 20, y: 350, width: 200, height: 40)
        searchButton.frame = CGRect(x: 20, y: 400, width: 200, height: 40)
        
        // Add subviews
        view.addSubview(songLabel)
        view.addSubview(songTextField)
        view.addSubview(venueTextField)
        view.addSubview(startDateTextField)
        view.addSubview(endDateTextField)
        view.addSubview(minRatingTextField)
        view.addSubview(collectionTextField)
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
        
        //self.searchTermsModel.sbdOnly = sbdOnly?.toggle()
        
        // Set the selected collection
        if let selectedIndex = CollectionConfig.collectionsText.firstIndex(of: collectionTextField.text ?? "") {
            self.searchTermsModel.collection = CollectionConfig.collections[selectedIndex]
        }
        
        view.endEditing(true)
        performSegue(withIdentifier: "showSearchResults", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSearchResults" {
            print("showSearchResults Segue")
            if let target = segue.destination as? ShowsListViewController {
                target.resetMonth()
                target.getIASearchTerm(searchTermsModel: self.searchTermsModel)
            }
        }
    }
}

// MARK: - UIPickerViewDelegate & UIPickerViewDataSource
extension SearchViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return CollectionConfig.collectionsText.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return CollectionConfig.collectionsText[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        collectionTextField.text = CollectionConfig.collectionsText[row]
    }
}
