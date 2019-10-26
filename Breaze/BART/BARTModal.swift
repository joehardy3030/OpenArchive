//
//  BARTModal.swift
//  Breaze
//
//  Created by Joe Hardy on 4/24/19.
//  Copyright © 2019 Carquinez. All rights reserved.
//

import UIKit

class BARTModal: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    var delegate: ModalDelegate?
    var newStation = BARTStation(abbreviation: "ECPL", direction: "n")

    @IBOutlet var stationPicker: UIPickerView!
    
    var stationPickerData: [String] = [String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        // Create save button
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: Selector(("handleSave")))
       // saveButton.tintColor = UIColor.commonTextColor()
        // Create cancel button
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: Selector(("handleCancel")))
       // cancelButton.tintColor = UIColor.commonTextColor()
        // Add the buttons to the navigation bar
        let topViewController = self.navigationController!.topViewController
        topViewController!.navigationItem.rightBarButtonItem = saveButton
        topViewController!.navigationItem.leftBarButtonItem = cancelButton
  //      stationPicker = UIPickerView()
        if self.stationPicker != nil {
            self.stationPicker.dataSource = self
            self.stationPicker.delegate = self
        }
        stationPickerData = ["12TH",
                       "16TH",
                       "19TH",
                       "24TH",
                       "ASHB",
                       "BALB",
                       "BAYF",
                       "CAST",
                       "CIVC",
                       "COLS",
                       "COLM",
                       "CONC",
                       "DALY",
                       "DBRK",
                       "DUBL",
                       "DELN",
                       "PLZA",
                       "EMBR",
                       "FRMT",
                       "FTVL",
                       "GLEN",
                       "HAYW",
                       "LAFY",
                       "LAKE",
                       "MCAR",
                       "MLBR",
                       "MONT",
                       "NBRK",
                       "NCON",
                       "OAKL",
                       "ORIN",
                       "PITT",
                       "PHIL",
                       "POWL",
                       "RICH",
                       "ROCK",
                       "SBRN",
                       "SFIA",
                       "SANL",
                       "SHAY",
                       "SSAN",
                       "UCTY",
                       "WCRK",
                       "WDUB",
                       "WOAK",
                       "WARM"]
    }
    
    
    @IBAction func dismissViewController(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    
    @objc func handleCancel() {
        print("Aborting changes to device")
        // Ask the view controller that presented us to dismiss us...
        self.dismiss(animated: true, completion: nil)
    }

    @objc func handleSave() {
        print("Doing save things")
        if let delegate = self.delegate {
            delegate.changeStation(station: newStation)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return stationPickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return stationPickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        newStation.abbreviation = stationPickerData[row]
    }

    
}
