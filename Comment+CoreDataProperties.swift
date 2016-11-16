//
//  Comment+CoreDataProperties.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 11/12/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Comment {

    @nonobjc open override class func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest(entityName: "Comment");
    }

    @NSManaged public var timeSent: Date?
    @NSManaged public var text: String?
    @NSManaged public var username: String?
    @NSManaged var message: Message// not right?
}
