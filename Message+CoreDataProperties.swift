//
//  Message+CoreDataProperties.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 12/11/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation

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

    func initFromLocation(_ location: CLLocation) {
        self.latitude           = location.coordinate.latitude as NSNumber?
        self.longitude          = location.coordinate.longitude as NSNumber?
        self.altitude           = location.altitude as NSNumber?
        self.timestamp          = location.timestamp as NSDate?
        
        self.horizontalAccuracy = location.horizontalAccuracy as NSNumber?
        self.verticalAccuracy   = location.verticalAccuracy as NSNumber?
        self.speed              = location.speed as NSNumber?
        self.course             = location.course as NSNumber?
    }
    
    
    func cdlocation() -> CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: self.latitude!.doubleValue, longitude: self.longitude!.doubleValue),
            altitude: self.altitude!.doubleValue,
            horizontalAccuracy: self.horizontalAccuracy!.doubleValue,
            verticalAccuracy: self.verticalAccuracy!.doubleValue,
            course: self.course!.doubleValue,
            speed: self.speed!.doubleValue,
            timestamp: self.timestamp! as Date
        )
    }
    
    
    func calculate() -> Bool{
        //in essence: timedropped + timelimit = timeDeadline; timeCurrent - timeDeadline = timeLeft
        //convert timeleft to days hours
        
        let timeDropped = self.timeDropped!
        
        let timeDeadline:Date = timeDropped.addingTimeInterval(Double(timeLimit!) * 3600) as Date
        
        let timeCurrent: Date = Date()
        
        var timeLeft = timeCurrent.timeIntervalSince(timeDeadline) / 3600
        timeLeft = round(timeLeft * -1)
        
        
        /* let timeDeadline:Date = timeDropped.addingTimeInterval(Double(timeLimit) * 3600)// date crumbs dies
         
         let timeCurrent: Date = Date()//current date and time
         
         var timeLeft = timeCurrent.timeIntervalSince(timeDeadline) / 3600//time remaining in hours
         
         timeLeft = round(timeLeft * -1)// since its the future we multiply by -1 and round off the %hours
         
         return timeLeft//returns*/
        
        if timeLeft > 0 {
            return true//the message is still alive
        } else{
            return false// tis is dead rip in pease
        }
    }
    
    
    @objc(addCommentsObject:)
    @NSManaged public func addToComments(_ value: Comment)

    @objc(removeCommentsObject:)
    @NSManaged public func removeFromComments(_ value: Comment)

    @objc(addComments:)
    @NSManaged public func addToComments(_ values: NSSet)

    @objc(removeComments:)
    @NSManaged public func removeFromComments(_ values: NSSet)

}
