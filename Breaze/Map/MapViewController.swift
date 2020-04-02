//
//  MapViewController.swift
//  Breaze
//
//  Created by Joe Hardy on 4/1/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.userTrackingMode = .follow
        let annotations = LocationsStorage.shared.locations.map { annotationForLocation($0) }
        mapView.addAnnotations(annotations)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(newLocationAdded(_:)),
                                               name: .newLocationSaved,
                                               object: nil)
    }
    

    @IBAction func addItem(_ sender: Any) {
        guard let currentLocation = mapView.userLocation.location else {
            return
        }
        LocationsStorage.shared.saveCLLocationToDisk(currentLocation)
        print(currentLocation.coordinate)
    }
    
    @objc func newLocationAdded(_ notification: Notification) {
      guard let location = notification.userInfo?["location"] as? Location else {
        return
      }

      let annotation = annotationForLocation(location)
      mapView.addAnnotation(annotation)
    }
    
    func annotationForLocation(_ location: Location) -> MKAnnotation {
        let annotation = MKPointAnnotation()
        annotation.title = location.dateString
        annotation.coordinate = location.coordinates
        return annotation
    }
}
