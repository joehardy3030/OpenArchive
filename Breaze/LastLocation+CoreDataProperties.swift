//
//  LastLocation+CoreDataProperties.swift
//  Breaze
//
//  Created by Joe Hardy on 6/28/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//
//

import Foundation
import CoreData


extension LastLocation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LastLocation> {
        return NSFetchRequest<LastLocation>(entityName: "LastLocation")
    }

    @NSManaged public var latitude: String?
    @NSManaged public var longitude: String?
    @NSManaged public var dateSaved: NSDate?

}
