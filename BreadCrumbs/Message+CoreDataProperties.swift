//
//  Message+CoreDataProperties.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 12/13/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation

extension Message {

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


}

// MARK: Generated accessors for comments
extension Message {
    
    func initFromLocation(_ location: CLLocation) {
        self.latitude           = location.coordinate.latitude as NSNumber?
        self.longitude          = location.coordinate.longitude as NSNumber?
        self.altitude           = location.altitude as NSNumber?
        self.timestamp          = location.timestamp
        
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
