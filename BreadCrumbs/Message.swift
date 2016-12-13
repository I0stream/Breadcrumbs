//
//  Message+CoreDataClass.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 12/11/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import Foundation
import CoreData


public class Message: NSManagedObject {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Message> {
        return NSFetchRequest<Message>(entityName: "Message");
    }
    
    //Location Attributes
    @NSManaged var altitude: NSNumber?
    @NSManaged var course: NSNumber?
    @NSManaged var horizontalAccuracy: NSNumber?
    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var speed: NSNumber?
    @NSManaged var timestamp: Date?
    @NSManaged var verticalAccuracy: NSNumber?
    
    //MSG Attributtes
    @NSManaged var senderName: String?
    @NSManaged var text: String?
    @NSManaged var timeDropped: Date?
    @NSManaged var timeLimit: NSNumber?
    @NSManaged var senderuuid: String?
    @NSManaged var votevalue: NSNumber?
    @NSManaged var recorduuid: String?
    @NSManaged var viewedOther: NSNumber?//stored as a 0 or 1 1 == seen/true
    @NSManaged var hasVoted: NSNumber?//stored as a 0,1 zero is no vote
    @NSManaged var addressStr: String?//stores an address like this "\(locality!), \(thoroughfare!), \(country!)"
    //@NSManaged var creatorUniqueID: String //used to test messages against each other, allows multiple people to have the same name
    @NSManaged var comments: [Comment]?
    
    //@NSManaged public var comments: NSSet?
}
