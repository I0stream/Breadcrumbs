//
//  Message+CoreDataProperties.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 12/11/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import Foundation
import CoreData


extension Message {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Message> {
        return NSFetchRequest<Message>(entityName: "Message");
    }

    @NSManaged public var addressStr: String?
    @NSManaged public var altitude: NSNumber?
    @NSManaged public var course: NSNumber?
    @NSManaged public var hasVoted: NSNumber?
    @NSManaged public var horizontalAccuracy: NSNumber?
    @NSManaged public var latitude: NSNumber?
    @NSManaged public var longitude: NSNumber?
    @NSManaged public var recorduuid: String?
    @NSManaged public var senderName: String?
    @NSManaged public var senderuuid: String?
    @NSManaged public var speed: NSNumber?
    @NSManaged public var text: String?
    @NSManaged public var timeDropped: NSDate?
    @NSManaged public var timeLimit: NSNumber?
    @NSManaged public var timestamp: NSDate?
    @NSManaged public var verticalAccuracy: NSNumber?
    @NSManaged public var viewedOther: NSNumber?
    @NSManaged public var votevalue: NSNumber?
    @NSManaged public var comments: NSSet?

}

// MARK: Generated accessors for comments
extension Message {

    @objc(addCommentsObject:)
    @NSManaged public func addToComments(_ value: Comment)

    @objc(removeCommentsObject:)
    @NSManaged public func removeFromComments(_ value: Comment)

    @objc(addComments:)
    @NSManaged public func addToComments(_ values: NSSet)

    @objc(removeComments:)
    @NSManaged public func removeFromComments(_ values: NSSet)

}
