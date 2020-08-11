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
import FirebaseUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, FUIAuthDelegate {

    var window: UIWindow?
    let center = UNUserNotificationCenter.current()
    fileprivate(set) var auth: Auth!
    fileprivate(set) var authUI: FUIAuth!

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print(url)
        return true 
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in }
        do {
              //options: AVAudioSession.CategoryOptions.mixWithOthers
              try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
              try AVAudioSession.sharedInstance().setActive(true)
          }
          catch {
              print("nope")
          }
        //FirebaseApp.configure()
        setupFirebase()
        guard let rvc = self.window?.rootViewController as? ArchiveSuperViewController else {fatalError()}
        rvc.player = AudioPlayerArchive()
        rvc.auth = self.auth
        rvc.authUI = self.authUI
        
        //print(rvc.player)
        // Dependency injection is fun! Remind me again what's so bad about singeltons?
        /*
        if let tbc = window?.rootViewController as? UITabBarController {
            if let rvc = tbc.viewControllers?[0] as? DownloadsNavigationController {
                if let vc = rvc.topViewController as? DownloadsViewController {
                    vc.player = AudioPlayerArchive()
                }
            }
        }
        */

        return true
    }

    func setupFirebase() {
        FirebaseApp.configure()
        self.auth = Auth.auth()
        self.authUI = FUIAuth.defaultAuthUI()
        // You need to adopt a FUIAuthDelegate protocol to receive callback
        authUI.delegate = self
        let providers: [FUIAuthProvider] = [
            FUIPhoneAuth(authUI:authUI),
            FUIEmailAuth()
        ]
        authUI.providers = providers
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
      //  self.saveContext()
    }
    
}

