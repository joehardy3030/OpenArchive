//
//  SceneDelegate.swift
//  ChateauArchive
//
//  Created by Joseph Hardy on 1/11/21.
//

import UIKit
import ARKit
import Firebase
import FirebaseUI
// import CarPlay

//let sharedPlayer = AudioPlayerArchive()
@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate, FUIAuthDelegate {

    var window: UIWindow?
    let center = UNUserNotificationCenter.current()
    fileprivate(set) var auth: Auth!
    fileprivate(set) var authUI: FUIAuth!
    fileprivate(set) var db: Firestore!


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        print(scene)
        // guard if
        if FirebaseApp.app() == nil {
            setupFirebase()
        }
        else {
            self.db = Firestore.firestore()
        }

        center.requestAuthorization(options: [.alert, .sound]) { granted, error in }
        do {
              //options: AVAudioSession.CategoryOptions.mixWithOthers
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
          }
          catch {
              print("nope")
          }

        
        guard let rvc = self.window?.rootViewController as? ArchiveSuperViewController else {fatalError()}
        rvc.player = AudioPlayerArchive.shared //sharedPlayer //AudioPlayerArchive()
        rvc.auth = self.auth
        rvc.authUI = self.authUI
        rvc.db = self.db
        
        /*
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        window.makeKeyAndVisible()
        */

    }

    func setupFirebase() {
        FirebaseApp.configure()
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
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}
