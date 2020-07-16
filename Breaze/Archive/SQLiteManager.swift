//
//  SQLiteManager.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/13/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import SQLite3

class SQLiteManager: NSObject {
    override init() {
        super.init()
        let sqliteVersion = sqlite3_libversion()
        let sqliteVersionString = NSString(utf8String: sqliteVersion! )
        print("sqliteVersion: \(String(describing: sqliteVersion))")
        print("sqliteVersionString: \(String(describing: sqliteVersionString))")
        
    }
}
