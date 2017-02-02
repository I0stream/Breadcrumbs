//
//  Comment+CoreDataProperties.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 12/13/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import Foundation
import CoreData


extension Comment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Comment> {
        return NSFetchRequest<Comment>(entityName: "Comment");
    }

    @NSManaged public var text: String?
    @NSManaged public var timeSent: NSDate?
    @NSManaged public var username: String?
    @NSManaged public var userID: String?
    @NSManaged public var recorduuid: String?
    @NSManaged public var message: Message?
    @NSManaged public var markedForDelete: NSNumber?//0 is false 1 is true

}
