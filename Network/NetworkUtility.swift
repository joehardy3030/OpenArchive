//
//  NetworkUtility.swift
//  UpCog
//
//  Created by Joe Hardy on 7/13/19.
//  Copyright © 2019 Joe Hardy. All rights reserved.
//

import UIKit
import FirebaseFirestore
import GRDB

class NetworkUtility: NSObject {
    var db: Firestore?
    private let dbQueue: DatabaseQueue
    
    init(db: Firestore? = nil) {
        self.db = db
        self.dbQueue = LocalDatabase.shared.dbQueue
        super.init()
    }
    
    enum NetworkError: Error {
        case userNotAuthorized
        case notFullProfile
    }
    
    private func getUUID() -> String {
        UIDevice.current.identifierForVendor?.uuidString ?? ""
    }
    
    func addDownloadDataDoc(showMetadataModel: ShowMetadataModel?) -> String? {
        guard let model = showMetadataModel,
              let identifier = model.metadata?.identifier else {
            return nil
        }
        do {
            let jsonData = try JSONEncoder().encode(model)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            try dbQueue.write { db in
                try db.execute(sql: "INSERT OR REPLACE INTO downloads (identifier, data) VALUES (?, ?)",
                               arguments: [identifier, jsonString])
            }
            return identifier
        } catch {
            print("GRDB write error: \(error)")
            return nil
        }
    }

    func removeDownloadDataDoc(docID: String?) {
        guard let docID = docID else { return }
        do {
            try dbQueue.write { db in
                try db.execute(sql: "DELETE FROM downloads WHERE identifier = ?", arguments: [docID])
            }
        } catch {
            print("GRDB delete error: \(error)")
        }
    }
    
    func addShareDataDoc(shareMetadataModel: ShareMetadataModel?) -> String? {
        guard let model = shareMetadataModel else { return nil }
        do {
            let jsonData = try JSONEncoder().encode(model)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            try dbQueue.write { db in
                try db.execute(sql: "INSERT OR REPLACE INTO share (id, data) VALUES ('shareShow', ?)", arguments: [jsonString])
            }
            return "shared"
        } catch {
            print("GRDB write share error: \(error)")
            return nil
        }
    }
    
    func updateSharedPlayPause(broadcastIsPlaying: Bool?) {
        guard let isPlaying = broadcastIsPlaying else { return }
        do {
            let share: ShareMetadataModel? = try dbQueue.read { db in
                if let row = try Row.fetchOne(db, sql: "SELECT data FROM share WHERE id = 'shareShow'") {
                    if let jsonString: String = row["data"],
                       let data = jsonString.data(using: .utf8) {
                        return try JSONDecoder().decode(ShareMetadataModel.self, from: data)
                    }
                }
                return nil
            }
            var updated = share ?? ShareMetadataModel()
            updated.isPlaying = isPlaying
            _ = addShareDataDoc(shareMetadataModel: updated)
        } catch {
            print("GRDB update share error: \(error)")
        }
    }
    
    func getDownloadDoc(identifier: String?) -> String? {
        return identifier
    }
    
    func getAllDownloadDocs(decade: String?, completion: @escaping ([ShowMetadataModel]?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                var shows: [ShowMetadataModel] = []
                try self.dbQueue.read { db in
                    let rows = try Row.fetchAll(db, sql: "SELECT data FROM downloads")
                    for row in rows {
                        if let jsonString: String = row["data"],
                           let data = jsonString.data(using: .utf8) {
                            if let show = try? JSONDecoder().decode(ShowMetadataModel.self, from: data) {
                                shows.append(show)
                            }
                        }
                    }
                }
                if let decade = decade {
                    let allowedYears: [String]
                    switch decade {
                    case "1960s": allowedYears = ["1965","1966","1967","1968","1969"]
                    case "1970s": allowedYears = ["1970","1971","1972","1973","1974","1975","1976","1977","1978","1979"]
                    case "1980s": allowedYears = ["1980","1981","1982","1983","1984","1985","1986","1987","1988","1989"]
                    case "1990s": allowedYears = ["1990","1991","1992","1993","1994","1995","1996","1997","1998","1999"]
                    case "2000s": allowedYears = ["2000","2001","2002","2003","2004","2005","2006","2007","2008"]
                    case "2010s": allowedYears = ["2010","2011","2012","2013","2014","2015","2016","2017","2018","2019"]
                    case "2020s": allowedYears = ["2020","2021","2022","2023","2024","2025"]
                    default: allowedYears = []
                    }
                    shows = shows.filter { allowedYears.contains($0.metadata?.year ?? "") }
                }
                completion(shows)
            } catch {
                print("GRDB fetch error: \(error)")
                completion(nil)
            }
        }
    }
    
    func getSharedDoc(completion: @escaping ([ShareMetadataModel]?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let shareModel: ShareMetadataModel? = try self.dbQueue.read { db in
                    if let row = try Row.fetchOne(db, sql: "SELECT data FROM share WHERE id = 'shareShow'") {
                        if let jsonString: String = row["data"],
                           let data = jsonString.data(using: .utf8) {
                            return try JSONDecoder().decode(ShareMetadataModel.self, from: data)
                        }
                    }
                    return nil
                }
                completion(shareModel != nil ? [shareModel!] : nil)
            } catch {
                print("GRDB shared fetch error: \(error)")
                completion(nil)
            }
        }
    }
    
    func getShareSnapshot(completion: @escaping (ShareMetadataModel?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let shareModel: ShareMetadataModel? = try self.dbQueue.read { db in
                    if let row = try Row.fetchOne(db, sql: "SELECT data FROM share WHERE id = 'shareShow'") {
                        if let jsonString: String = row["data"],
                           let data = jsonString.data(using: .utf8) {
                            return try JSONDecoder().decode(ShareMetadataModel.self, from: data)
                        }
                    }
                    return nil
                }
                completion(shareModel)
            } catch {
                print("GRDB shared snapshot error: \(error)")
                completion(nil)
            }
        }
    }
}


