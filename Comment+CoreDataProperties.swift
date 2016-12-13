//
//  Comment+CoreDataProperties.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 12/11/16.
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
    @NSManaged var message: Message?

}
