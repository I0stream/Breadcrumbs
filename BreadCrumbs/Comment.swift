//
//  Comment+CoreDataClass.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 11/12/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


open class Comment: NSManagedObject {

}
extension Comment {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Comment> {
        return NSFetchRequest<Comment>(entityName: "Comment");
    }
    
    @NSManaged public var text: String?
    @NSManaged public var timeSent: NSDate?
    @NSManaged public var username: String?
    @NSManaged var message: Message?
    
}
