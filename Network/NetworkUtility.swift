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

//    static let defaultDateEncodingStrategy: DateEncodingStrategy = .iso8601
    
    enum NetworkError: Error {
        case userNotAuthorized
        case notFullProfile
    }
    
    func getUUID() -> String {
        if let uuid = UIDevice.current.identifierForVendor?.uuidString {
            //self.present(vc, animated: true, completion: nil)print(uuid)
            return uuid
        }
        else {
            return ""
        }
    }

    func addDownloadDataDoc(showMetadataModel: ShowMetadataModel?) -> String? {
        let db = Firestore.firestore()
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
        let db = Firestore.firestore()
        guard let s = shareMetadataModel else { return "no data" }
        guard let docID = shareMetadataModel?.showMetadataModel?.metadata?.identifier else { return "no id" }
        
        //let uuid = getUUID()
        
        let docData = try! FirestoreEncoder().encode(s)
        db.collection("share").document(docID).setData(docData) { error in
            if let error = error {
                print("Error writing document: \(error)")
            } else {
                print("Document successfully written!")
            }
        }
        return docID
    }
    
    func getDownloadDoc(identifier: String?) -> String? {
        let db = Firestore.firestore()
        //var ref: DocumentReference? = nil
        //guard let s = showMetadataModel else { return "no data" }
        guard let docID = identifier else { return "no id" }
        
        let uuid = getUUID()
        //let doc = ["uuid" : uuid]
        
        db.collection(uuid).document("downloads").collection("shows").document(docID).addSnapshotListener { document, error in
            if let document = document {
                let model = try! FirestoreDecoder().decode(ShowMetadataModel.self, from: document.data()!)
               // print("Model: \(model)")
            } else {
                print("Document does not exist")
            }
        }
        
        return docID
    }
    
    func getAllDownloadDocs(completion: @escaping ([ShowMetadataModel]?) -> Void) {
        let db = Firestore.firestore()
        let uuid = getUUID()
       // var show = ShowMetadataModel()
        var shows: [ShowMetadataModel] = []
        print("called get all downloaded docs")
        let docRef = db.collection(uuid).document("downloads").collection("shows")
        docRef.addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    let show = try! FirestoreDecoder().decode(ShowMetadataModel.self, from: document.data())
                    //print("\(document.documentID) => \(document.data())")
                    shows.append(show)
                }
                completion(shows)
            }
        }
    }
    
    func getSharedDoc(completion: @escaping ([ShareMetadataModel]?) -> Void) {
        let db = Firestore.firestore()
        print("called shared doc")
        var shows: [ShareMetadataModel] = []
        let docRef = db.collection("share")
        docRef.addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    let show = try! FirestoreDecoder().decode(ShareMetadataModel.self, from: document.data())
                    //print("\(document.documentID) => \(document.data())")
                    shows.append(show)
                }
                completion(shows)
            }
        }
    }


    //let auth = Auth()
    // private let auth: Auth
    
    /*
    init(auth: Auth) {
        self.auth = auth
        super.init()
    }
    */
    /*
    private func promiseFirUser() -> Promise<User> {
        if let user = self.auth.currentUser {
            return Promise.value(user)
        } else {
            return Promise(error: NetworkError.userNotAuthorized)
        }
    }

    private func promiseUserId() -> Promise<String> {
        if let user = self.auth.currentUser {
            return Promise<String>.value(user.uid)
        } else {
            return Promise(error: NetworkError.userNotAuthorized)
        }
    }
    */
    /*
    private func getUserUID() -> String {
        var userUID: String = "anonymous"
        if let user = self.auth.currentUser {
            userUID = user.uid
            print("userUID is ", userUID)
        } else {
            print("no user signed in")
        }
        return userUID
    }

    func signOutUser() throws {
        var userUID: String = "anonymous"
        if let user = self.auth.currentUser {
            userUID = user.uid
            print("userUID is ", userUID)
        } else {
            print("no user signed in")
        }
        try auth.signOut()
    }
    */

    func addGoalFirebase(with dict: [String: Any]) -> String? {
        let db = Firestore.firestore()
        var ref: DocumentReference? = nil
        var doc = dict

        doc["createdAt"] = FieldValue.serverTimestamp()
        doc["updatedAt"] = FieldValue.serverTimestamp()

        ref = db.collection("goals").addDocument(data: doc)
        { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(String(describing: ref!.documentID))")
            }
        }

        if let id = ref?.documentID {
            return id
        } else {
            return "Error"
        }
    }

    func addHRFirestore(with dict: [String: Any]) -> String? {
        let db = Firestore.firestore()
        var ref: DocumentReference? = nil
        var doc = dict

        doc["createdAt"] = FieldValue.serverTimestamp()
        doc["updatedAt"] = FieldValue.serverTimestamp()
        doc["userUID"] = getUUID()

        ref = db.collection("heartRate").addDocument(data: doc)
        { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(String(describing: ref!.documentID))")
            }
        }

        if let id = ref?.documentID {
            return id
        } else {
            return "Error"
        }
    }

    func addHRDatabase(with dict: [String: Any]) {
        //https://upcog-e2a09.firebaseio.com/
        let ref: DatabaseReference = Database.database().reference()

        let uuid = getUUID()

        ref.child("heartRate").child(uuid).setValue(dict) {
            (error: Error?, ref: DatabaseReference) in
            if let error = error {
              //  SOLogError("HR Data could not be saved: \(error).")
            } else {
             //   SOLogInfo("HR Data saved successfully!")
            }
        }

    }
/*
    func deserializeGoalFirebase(with document: DocumentSnapshot) -> DailyGoal {
        guard let goal = try? FirestoreDecoder().decode(DailyGoal.self, from: document.data()!) else {
            return DailyGoal()
        }
        return goal
    }
*/
    /*
    func deserializeCourseFirebase(with document: DocumentSnapshot) -> UserCourse {
        let errorCourse = UserCourse()
        guard let course = try? FirestoreDecoder().decode(UserCourse.self, from: document.data()!) else {
            print("Error deserializing")
            return errorCourse
        }
        return course
    }
 */

    /*
    func getGoalsFirebase() -> [DailyGoal] {
        let db = Firestore.firestore()
        let docRef = db.collection("goals")
        var goal = DailyGoal()
        var goals: [DailyGoal] = []

        docRef.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    goal = self.deserializeGoalFirebase(with: document)
                    print("\(document.documentID) => \(document.data())")
                    goals.append(goal)
                }
            }
        }
        return goals
    }

 */
    /*
    func fetchGoalsFirebase(completion: @escaping ([DailyGoal]) -> Void) {
        let db = Firestore.firestore()
        let docRef = db.collection("goals")
        var goal = DailyGoal()
        var goals: [DailyGoal] = []
        docRef.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    goal = self.deserializeGoalFirebase(with: document)
                    print("\(document.documentID) => \(document.data())")
                    goals.append(goal)
                }
                completion(goals)
            }
        }
    }
    */
    
    /*
    func eventListenerGoalsFirebase(completion: @escaping ([DailyGoal]) -> Void) {
        let db = Firestore.firestore()
        let docRef = db.collection("goals")
        var goal = DailyGoal()
        var goals: [DailyGoal] = []
        docRef.addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    goal = self.deserializeGoalFirebase(with: document)
                    // print("\(document.documentID) => \(document.data())")
                    goals.append(goal)
                }
                completion(goals)
            }
        }
    }
    */
    /*
    func eventListenerUserGoalsFirebase(completion: @escaping ([DailyGoal], UserCourse, Int) -> Void) {
        let db = Firestore.firestore()
        var course = UserCourse()
        let userUID = getUserUID()

        let docRefUserGoals = db.collection("user_goals")
                .whereField("userUID", isEqualTo: userUID)
        //  .order(by: "createdAt", descending: true).limit(to: 1)

        docRefUserGoals.addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    course = self.deserializeCourseFirebase(with: document)
                }
                self.joinUserGoalsDailyGoals(course: course, db: db, completion: completion)
            }
        }
    }
    */
    
    /*
    func joinUserGoalsDailyGoals(course: UserCourse, db: Firestore, completion: @escaping ([DailyGoal], UserCourse, Int) -> Void) {
        var dailyGoal = DailyGoal()
        var dailyGoals: [DailyGoal] = []
        if let courseGoals = course.courseGoals {
            for userGoal in courseGoals {
                if let goalID = userGoal.goalID {
                    let docRef = db.collection("goals")
                            .whereField("goalID", isEqualTo: goalID)
                    docRef.addSnapshotListener { (querySnapshot, error) in
                        if let error = error {
                            print("Error getting documents: \(error)")
                        } else {
                            for document in querySnapshot!.documents {
                                dailyGoal = self.deserializeGoalFirebase(with: document)
                                dailyGoal.completed = userGoal.completed
                                dailyGoals.append(dailyGoal)
                            }
                        }
                        if dailyGoals.count == courseGoals.count {
                            completion(dailyGoals, course, courseGoals.count)
                        }
                    }
                }
            }
        }
    }
    */
    
    /*
    func updateGoalCompleted(userCourse: UserCourse, documentID: String, goalID: Int) {
        let db = Firestore.firestore()
        let docRef = db.collection("user_goals").document(documentID)

        if let numGoals = userCourse.courseGoals?.count {
            for i in 0...(numGoals - 1) {
                if goalID == userCourse.courseGoals?[i].goalID {
                    userCourse.courseGoals?[i].completed = true
                    let data = try! FirebaseEncoder().encode(userCourse)
                    docRef.updateData(data as! [AnyHashable: Any]) { err in
                        if let err = err {
                            print("Error writing document: \(err)")
                        } else {
                            print("Document successfully written!")
                        }
                    }
                }
            }
        }
    }
    
    func setGoalComplete(goalID: Int) {
        let db = Firestore.firestore()
        let docRef = db.collection("user_goals")
                .whereField("userUID", isEqualTo: getUserUID())

        docRef.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    let userCourse = self.deserializeCourseFirebase(with: document)
                    self.updateGoalCompleted(userCourse: userCourse, documentID: document.documentID, goalID: goalID)
                    //print(userCourse.courseGoals?[0].goalID as Any)
                    //print("\(document.documentID) => \(document.data())")
                }
            }
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    // MARK: shared logic

    ///////////////////////////////////////////////////////////////////////////
    // MARK: user profile data


    func loadLocalProfile() -> UserProfile? {
        do {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsURL.appendingPathComponent("profile.json")
            let fileData = try Data(contentsOf: fileURL)
            let jsonDecoder = JSONDecoder()
            NetworkUtility.defaultDateEncodingStrategy.applyTo(jsonDecoder)
            let userProfile: UserProfile = try jsonDecoder.decode(UserProfile.self, from: fileData)
            return userProfile
        } catch {
            return nil
        }
    }

    private func saveLocalProfile(_ userProfile: UserProfile) throws -> Void {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent("profile.json")
        let jsonEncoder = JSONEncoder()
        NetworkUtility.defaultDateEncodingStrategy.applyTo(jsonEncoder)
        let fileData = try jsonEncoder.encode(userProfile)
        try fileData.write(to: fileURL, options: .atomic)
        SOLogDebug("User profile is saved to \(fileURL)")
    }

    func saveUserProfile(userProfile: UserProfile) -> Promise<Void> {
        self.promiseFirUser().then { (firUser: User) -> Promise<User> in
            // update also the Displayable Name in the FirebaseAuth so the Unity app can easily get it
            if (userProfile.userName != firUser.displayName) {
                let changeRequest = firUser.createProfileChangeRequest()
                changeRequest.displayName = userProfile.userName
                return changeRequest.promiseCommitChanges().map { firUser }
            } else {
                return Promise.value(firUser)
            }
        }.map { firUser in
            let userId = firUser.uid
            let now = Date()
            if userProfile.createdDate == nil {
                userProfile.createdDate = now
            }
            userProfile.lastUpdateDate = now
            let serverProfile = UserProfileServerRecord(userProfile)
            let encoder = FirebaseEncoder()
            NetworkUtility.defaultDateEncodingStrategy.applyTo(encoder)
            let profileFields = try encoder.encode(serverProfile)
            return (userId, profileFields as! [String: Any])
        }.then { (tuple: (String, [String: Any])) throws -> Promise<Void> in
            let (userId, profileFields) = tuple
            let db = Firestore.firestore()
            let docRef: DocumentReference = db.collection("users").document(userId)
            return docRef.promiseSetData(profileFields, merge: true)
        }.done { (ignore: Void) throws -> Void in
            SOLogDebug("User profile document successfully saved to the server!")
            // save a copy of profile locally to track cache of the images
            try self.saveLocalProfile(userProfile)
        }
    }

    */
    
    /*
    func loadUserProfileFromServer(forceRefresh: Bool) -> Promise<UserProfile> {
        let oldLocalProfile = self.loadLocalProfile()
        let db = Firestore.firestore()
        let userId = getUserUID()
        let docRef = db.collection("users").document(userId)

        return docRef.promiseGetDocument(source: forceRefresh ? .server : .default).map { document in
            let decoder = FirebaseDecoder()
            NetworkUtility.defaultDateEncodingStrategy.applyTo(decoder)
            let data = document.data()
            let serverProfile = try decoder.decode(UserProfileServerRecord.self, from: data)
            let newLocalProfile = (oldLocalProfile?.userId == userId) ? oldLocalProfile! : UserProfile()
            newLocalProfile.userId = userId
            serverProfile.mergeIntoLocalProfile(newLocalProfile)
            try self.saveLocalProfile(newLocalProfile)
            return newLocalProfile
        }.then { (newLocalProfile: UserProfile) -> Promise<UserProfile> in
            // if profile is not full, don't even try to download images as they might be missing
            if (!newLocalProfile.fullyFilled) {
                throw NetworkError.notFullProfile
            }
            // TODO [SG]: download images concurrently, it requires moving out the
            // .saveProfile logic to avoid races there
            return self.refreshProfileImageFromServer(kind: .userSelf, userProfile: newLocalProfile).then { ignore in
                return self.refreshProfileImageFromServer(kind: .loved, userProfile: newLocalProfile).map { (tuple: (Bool, UserProfile)) in
                    let (refreshed, newLocalProfile) = tuple
                    return newLocalProfile
                }
            }
        }
    }

    private static func getProfileImageLocalUrl(kind: ProfileImageKind) -> URL {
        let imageFileName = kind.getFileName()
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(imageFileName)
        return fileURL
    }

    func loadLocalProfileImage(kind: ProfileImageKind) -> UIImage? {
        let fileURL = NetworkUtility.getProfileImageLocalUrl(kind: kind)
        return UIImage(contentsOfFile: fileURL.relativePath)
    }

    private func getProfileImageStorageRef(kind: ProfileImageKind) -> StorageReference {
        let storage = Storage.storage()
        let imagesFolderRef: StorageReference = storage.reference(withPath: "user_images")
        let userID: String = self.getUserUID()
        let userFolderRef: StorageReference = imagesFolderRef.child(userID)
        let imageFileName = kind.getFileName()
        let imageStorageRef: StorageReference = userFolderRef.child(imageFileName)
        return imageStorageRef
    }

    func refreshProfileImageFromServer(kind: ProfileImageKind, userProfile: UserProfile) -> Promise<(Bool, UserProfile)> {
        let imageInfo = kind.getProfileImageInfo(userProfile: userProfile)
        let helper = ImageStorageHelper(userId: userProfile.userId!)
        let location = ProfileImageStorageLocation(kind)
        return helper.retrieveImageEx(fromStorageLocation: location, imageInfo: imageInfo).map { result in
            if result.image != nil && !result.fromCache {
                SOLogDebug("Updated profile image \(kind) from the server")
                // save profile to save the updated imageInfo
                try self.saveLocalProfile(userProfile)
                return (true, userProfile)
            } else {
                return (false, userProfile)
            }
        }
    }

    func saveProfileImage(kind: ProfileImageKind, userProfile: UserProfile, selectedImage: UIImage) -> Promise<Void> {
        return self.promiseUserId().then { (userId: String) -> Promise<Void> in
            let helper = ImageStorageHelper(userId: userId)
            let location = ProfileImageStorageLocation(kind)
            let imageInfo = kind.getProfileImageInfo(userProfile: userProfile)
            return helper.uploadImage(selectedImage, imageInfo: imageInfo, atStorageLocation: location)
        }.then { () -> Promise<Void> in
            return self.saveUserProfile(userProfile: userProfile)
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // MARK: user login/registered state

    private static let keyUserIsRegistered: String = "UserIsRegistered"

    func isLoggedIn() -> Bool {
        return self.auth.currentUser != nil
    }

    func getUserLoginState() -> UserLoginState {
        let isRegistered = UserDefaults.standard.bool(forKey: NetworkUtility.keyUserIsRegistered)
        if (!isRegistered) {
            return .notRegistered
        } else {
            if self.auth.currentUser != nil {
                return .loggedIn
            } else {
                return .loggedOut
            }
        }
    }

    func markUserAsRegistered() {
        UserDefaults.standard.set(true, forKey: NetworkUtility.keyUserIsRegistered)
    }

    // for crash handling
    static func markUserAsNotRegistered() {
        UserDefaults.standard.set(false, forKey: NetworkUtility.keyUserIsRegistered)
    }

    ///////////////////////////////////////////////////////////////////////////
    // MARK: check in

    static let yearMonthDateAgnosticFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = DateUtils.agnosticLocale
        formatter.dateFormat = "yyyy-MM"
        return formatter
    }()


    private func getCheckInsFolderDatabaseRef(userId: String, date: Date) -> DatabaseReference {
        let databaseRef = Database.database().reference()
        let yearMonthString = Self.yearMonthDateAgnosticFormatter.string(from: date)
        return databaseRef.child("checkins").child(userId).child(yearMonthString)
    }

    func saveCheckIn(_ checkInRecord: CheckInRecord) -> Promise<Void> {
        return self.promiseUserId().then { (userId: String) -> Promise<Void> in
            let folderRef = self.getCheckInsFolderDatabaseRef(userId: userId, date: checkInRecord.startDateTime)
            // new or existing record?
            let checkinRef = checkInRecord.id != nil ? folderRef.child(checkInRecord.id!) : folderRef.childByAutoId()

            let serverRecord = CheckInServerRecord(checkInRecord)
            let encoder = FirebaseEncoder()
            NetworkUtility.defaultDateEncodingStrategy.applyTo(encoder)
            let data = try encoder.encode(serverRecord)
            return checkinRef.promiseSetValue(data).map { savedRef in
                checkInRecord.id = savedRef.key
            }
        }
    }

    func saveCheckInImage(_ image: UIImage, forCheckIn checkInRecord: CheckInRecordWithImage) -> Promise<Void> {
        return  self.promiseUserId().then { (userId: String) -> Promise<Void> in
            let helper = ImageStorageHelper(userId: userId)
            let location = CheckInImageStorageLocation(checkInRecord)
            return helper.uploadImage(image, imageInfo: checkInRecord.selfImageInfo, atStorageLocation: location)
        }.then { () -> Promise<Void> in
            checkInRecord.selfImage = image
            return self.saveCheckIn(checkInRecord)
        }
    }

    func downloadCheckIns(forMonth date: Date) -> Promise<[CheckInRecord]> {
        return self.promiseUserId().then { (userId: String) -> Promise<DataSnapshot> in
            let folderRef = self.getCheckInsFolderDatabaseRef(userId: userId, date: date)
            return folderRef.promiseReadData()
        }.map { (snapshot: DataSnapshot) throws -> [CheckInRecord] in
            guard snapshot.exists() else {
                return []
            }
            let decoder = FirebaseDecoder()
            NetworkUtility.defaultDateEncodingStrategy.applyTo(decoder)

            var checkInRecords = try snapshot.children.map { (child: Any) -> CheckInRecord in
                let childSnapshot = child as! DataSnapshot
                let serverRecord: CheckInServerRecord = try decoder.decode(CheckInServerRecord.self, from: childSnapshot.value!)
                let checkInRecord = CheckInRecord(id: childSnapshot.key, serverRecord: serverRecord)
                return checkInRecord
            }
            checkInRecords.reverse() // ensure order with the newer on the top
            return checkInRecords
        }
    }

    func downloadCheckInImage(for checkInRecord: CheckInRecord) -> Promise<CheckInRecordWithImage> {
        //TODO [SG]: download the image and check local cache
        if checkInRecord.selfImageInfo.serverPath == nil {
            // there is no known image for the record
            let recordWithImage = CheckInRecordWithImage(record: checkInRecord, image: nil)
            return Promise.value(recordWithImage)
        } else {
            return  self.promiseUserId().then { (userId: String) -> Promise<UIImage?> in
                let helper = ImageStorageHelper(userId: userId)
                let location = CheckInImageStorageLocation(checkInRecord)
                return helper.retrieveImage(fromStorageLocation: location, imageInfo: checkInRecord.selfImageInfo)
            }.map { (image) -> CheckInRecordWithImage in
                // image might be nil for partial check in
                let recordWithImage = CheckInRecordWithImage(record: checkInRecord, image: image)
                return recordWithImage
            }
        }
    }


    ///////////////////////////////////////////////////////////////////////////

}

///////////////////////////////////////////////////////////////
enum UserLoginState {
    case notRegistered
    case loggedIn
    case loggedOut
}


///////////////////////////////////////////////////////////////

enum ProfileImageKind {
    case userSelf
    case loved

    func getFileName() -> String {
        switch self {
        case .userSelf:
            return "self.jpg"
        case .loved:
            return "loved.jpg"
        }
    }

    func getProfileImageInfo(userProfile: UserProfile) -> ImageInfo {
        switch self {
        case .userSelf:
            return userProfile.selfImageInfo
        case .loved:
            return userProfile.lovedImageInfo
        }
    }
    */
}


