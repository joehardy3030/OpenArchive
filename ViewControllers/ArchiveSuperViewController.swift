//
//  ArchiveSuperViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/24/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import FirebaseFirestore

class ArchiveSuperViewController: UIViewController {
    var network: NetworkUtility!
    let utils = Utils()
    let archiveAPI = ArchiveAPI()
    var prevController: ArchiveSuperViewController?
    var miniPlayer: MiniPlayerViewController?
    let player = AudioPlayerArchive.shared
    var isPlaying = false
    var db: Firestore!

    override func viewDidLoad() {
        super.viewDidLoad()
        if db != nil {
            network = NetworkUtility(db: db)
        }
        navigationController?.delegate = self
    }
}

extension ArchiveSuperViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let _ = viewController as? ArchiveSuperViewController {
        }
    }
}

@available(iOS 13.0, *)
extension ArchiveSuperViewController {
    func getMiniPlayerController() -> MiniPlayerViewController? {
        guard let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate else { return nil }
        //guard let sceneDelegate = UIApplication.shared.delegate as? SceneDelegate else { return nil }
        
        //guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        //if let vcs = appDelegate.window?.rootViewController?.children
        
        if let vcs = sceneDelegate.window?.rootViewController?.children
        {
            for vc in vcs {
                if let mp = vc as? MiniPlayerViewController {
                    return mp
                }
            }
        }
        return nil
    }
}

