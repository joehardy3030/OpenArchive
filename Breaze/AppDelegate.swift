//
//  AppDelegate.swift
//  Breaze
//
//  Created by Joseph Hardy on 1/31/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import UserNotifications

extension Notification.Name {
    static let alocation = Notification.Name("location")
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var currentLocation: CLLocation!
    let locationManager = CLLocationManager()
    let center = UNUserNotificationCenter.current()
    static let geoCoder = CLGeocoder()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.startMonitoringVisits()
        }
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in }

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        self.saveContext()
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Weather")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}


extension AppDelegate: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("error")
        
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]){
        let context = self.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "LastLocation", in: context)
        let lastLocation = NSManagedObject(entity: entity!, insertInto: context)
        
        self.currentLocation = locations.last
        lastLocation.setValue(String(self.currentLocation.coordinate.latitude), forKey: "latitude")
        lastLocation.setValue(String(self.currentLocation.coordinate.longitude), forKey: "longitude")
        lastLocation.setValue(Date(), forKey: "dateSaved")
        
        DispatchQueue.main.async{
            NotificationCenter.default.post(name: .alocation, object: nil)
            print("location Updated")
            self.saveContext()
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        // create CLLocation from the coordinates of CLVisit
        let clLocation = CLLocation(latitude: visit.coordinate.latitude, longitude: visit.coordinate.longitude)
        
        // Get location description
        AppDelegate.geoCoder.reverseGeocodeLocation(clLocation) { placemarks, _ in
          if let place = placemarks?.first {
            let description = "\(place)"
            self.newVisitReceived(visit, description: description)
          }
        }
    }
    
    func newVisitReceived(_ visit: CLVisit, description: String) {
        let location = Location(visit: visit, descriptionString: description)
        
        // 1
        let content = UNMutableNotificationContent()
        content.title = "New Journal entry 📌"
        content.body = location.description
        content.sound = .default

        // 2
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: location.dateString, content: content, trigger: trigger)

        // 3
        center.add(request, withCompletionHandler: nil)

        // Save location to disk        

    }
}
