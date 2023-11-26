//
//  NetworkUtility.swift
//  UpCog
//
//  Created by Joe Hardy on 7/13/19.
//  Copyright © 2019 Joe Hardy. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseDatabase
import FirebaseFirestore
import FirebaseStorage
import CodableFirebase
import PromiseKit

class NetworkUtility: NSObject {
    var db: Firestore!
    
    init(db: Firestore) {
        self.db = db
    }
    
    enum NetworkError: Error {
        case userNotAuthorized
        case notFullProfile
    }
    
    func getUUID() -> String {
        if let uuid = UIDevice.current.identifierForVendor?.uuidString {
            return uuid
        }
        else {
            return ""
        }
    }
    
    func addDownloadDataDoc(showMetadataModel: ShowMetadataModel?) -> String? {
        
        guard let s = showMetadataModel else { return "no data" }
        guard let docID = showMetadataModel?.metadata?.identifier else { return "no id" }
        
        let uuid = getUUID()

        let docData = try! FirestoreEncoder().encode(s)
        db.collection(uuid).document("downloads").collection("shows").document(docID).setData(docData) { error in
            if let error = error {
                print("Error writing document: \(error)")
            } else {
                print("Document successfully written!")
            }
        }
        return docID
    }

    func removeDownloadDataDoc(docID: String?) {
        guard let docID = docID else { return }
        let uuid = getUUID()
        db.collection(uuid).document("downloads").collection("shows").document(docID).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
    }
    
    func addShareDataDoc(shareMetadataModel: ShareMetadataModel?) -> String? {
        
        guard let s = shareMetadataModel else { return "no data" }
        let docData = try! FirestoreEncoder().encode(s)
        db.collection("share").document("shareShow").setData(docData) { error in
            if let error = error {
                print("Error writing document: \(error)")
            } else {
                print("Document successfully written!")
            }
        }
        return "shared"
    }
    
    func updateSharedPlayPause(broadcastIsPlaying: Bool?) {
        guard let p = broadcastIsPlaying else { return }
        db.collection("share").document("shareShow").updateData([
            "isPlaying": p
        ])
    }
    
    func getDownloadDoc(identifier: String?) -> String? {
        
        guard let docID = identifier else { return "no id" }
        let uuid = getUUID()
        db.collection(uuid).document("downloads").collection("shows").document(docID).addSnapshotListener { document, error in
            if let document = document {
                let _ = try! FirestoreDecoder().decode(ShowMetadataModel.self, from: document.data()!)
            } else {
                print("Document does not exist")
            }
        }
        
        return docID
    }
    
    func getAllDownloadDocs(decade: String?, completion: @escaping ([ShowMetadataModel]?) -> Void) {
        
        let uuid = getUUID()
        var shows: [ShowMetadataModel] = []
        var docRef: Query!
        var yearArray: [String]
        print("called get all downloaded docs")
        if let d = decade {
            switch d {
            case "1960s":
                yearArray = ["1965", "1966", "1967", "1968", "1969"]
            case "1970s":
                yearArray = ["1970", "1971", "1972", "1973", "1974", "1975", "1976", "1977", "1978", "1979"]
            case "1980s":
                yearArray = ["1980", "1981", "1982", "1983", "1984", "1985", "1986", "1987", "1988", "1989"]
            case "1990s":
                yearArray = ["1990", "1991", "1992", "1993", "1994", "1995"]
            default:
                yearArray = [""]
            }
            docRef = db.collection(uuid).document("downloads").collection("shows").whereField("metadata.year", in: yearArray)
        } else {
            docRef = db.collection(uuid).document("downloads").collection("shows")
        }
        // print(docRef!)
            
       // let docRef = db.collection(uuid).document("downloads").collection("shows")
        docRef.addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    let show = try! FirestoreDecoder().decode(ShowMetadataModel.self, from: document.data())
                    shows.append(show)
                }
                completion(shows)
            }
        }
    }
    
    func getSharedDoc(completion: @escaping ([ShareMetadataModel]?) -> Void) {
        
        print("called shared doc")
        var shows: [ShareMetadataModel] = []
        let docRef = db.collection("share").document("shareShow")
        docRef.addSnapshotListener { (document, error) in
            print("snapshot")
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                guard let data = document?.data() else { return }
                let show = try! FirestoreDecoder().decode(ShareMetadataModel.self, from: data)
                shows.append(show)
            }
            completion(shows)
        }
    }
    
    func getShareSnapshot(completion: @escaping (ShareMetadataModel?) -> Void) {
        print("called shared doc")
        let docRef = db.collection("share").document("shareShow")
        docRef.addSnapshotListener { (document, error) in
            print("snapshot")
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                guard let data = document?.data() else { return }
                let show = try! FirestoreDecoder().decode(ShareMetadataModel.self, from: data)
                completion(show)
            }
        }
        
    }
    
}


