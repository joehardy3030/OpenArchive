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
        //let db = Firestore.firestore()
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

    func addShareDataDoc(shareMetadataModel: ShareMetadataModel?) -> String? {
        //let db = Firestore.firestore()
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
    
    func getDownloadDoc(identifier: String?) -> String? {
        //        let db = Firestore.firestore()
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
    
    func getAllDownloadDocs(completion: @escaping ([ShowMetadataModel]?) -> Void) {
        //        let db = Firestore.firestore()
        let uuid = getUUID()
        var shows: [ShowMetadataModel] = []
        print("called get all downloaded docs")
        let docRef = db.collection(uuid).document("downloads").collection("shows")
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
        //let db = Firestore.firestore()
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


