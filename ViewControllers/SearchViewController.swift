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
        venueTextField.placeholder = "Venue"
        venueTextField.borderStyle = .roundedRect
        startDateTextField.placeholder = "Start Year (YYYY)"
        startDateTextField.borderStyle = .roundedRect
        endDateTextField.placeholder = "End Year (YYYY)"
        endDateTextField.borderStyle = .roundedRect
        minRatingTextField.placeholder = "1-5 stars min"
        minRatingTextField.borderStyle = .roundedRect
        
        // Configure button
        searchButton.setTitle("Search", for: .normal)
        searchButton.backgroundColor = .blue
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10.0
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let subviews = [songTextField, venueTextField, startDateTextField, endDateTextField, minRatingTextField, collectionTextField, searchButton]
        for subview in subviews {
            stackView.addArrangedSubview(subview)
            subview.heightAnchor.constraint(equalToConstant: 40).isActive = true
        }
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
        
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
