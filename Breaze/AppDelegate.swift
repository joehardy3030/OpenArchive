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
import ARKit
import Firebase
import FirebaseAuthUI
import FirebaseEmailAuthUI
import CarPlay

/*
class DeepLinkManager {
    static let shared = DeepLinkManager()
     
     private init() {}
     
     var deepLinkURL: URL?
}
*/

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, FUIAuthDelegate {

    //var window: UIWindow?
    let center = UNUserNotificationCenter.current()
    let archiveAPI = ArchiveAPI()
    fileprivate(set) var auth: Auth!
    fileprivate(set) var authUI: FUIAuth!
    fileprivate(set) var db: Firestore!

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("application did finish")
        FirebaseApp.configure()
        print("Firebase setup in AppDelegate")
        self.auth = Auth.auth()
        self.authUI = FUIAuth.defaultAuthUI()
        // You need to adopt a FUIAuthDelegate protocol to receive callback
        authUI.delegate = self
        let providers: [FUIAuthProvider] = [
            //FUIPhoneAuth(authUI:authUI),
            FUIEmailAuth()
        ]
        authUI.providers = providers
        self.db = Firestore.firestore()
        _ = sharedSetup()
        return true
 
    }
    
    /*
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        print("application open with url")
        return true
    }
    */
    
    func sharedSetup() -> Bool {
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in }
        do {
              //options: AVAudioSession.CategoryOptions.mixWithOthers
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            print("AV session")
          }
          catch {
              print("nope")
          }
 
        /*
        if FirebaseApp.app() == nil {
            print("Firebase Nil")
            setupFirebase()
        }
        else {
            self.db = Firestore.firestore()
            
        }
        */
        return true
    }
    
    /*
    func setupFirebase() {
        print("Firebase setup in AppDelegate")
        //FirebaseApp.configure()
        print(FirebaseApp.version())
        self.auth = Auth.auth()
        self.authUI = FUIAuth.defaultAuthUI()
        // You need to adopt a FUIAuthDelegate protocol to receive callback
        authUI.delegate = self
        let providers: [FUIAuthProvider] = [
            //FUIPhoneAuth(authUI:authUI),
            FUIEmailAuth()
        ]
        authUI.providers = providers
        self.db = Firestore.firestore()
    }

    */
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
      //  self.saveContext()
    }
    
}

