//
//  Message+CoreDataProperties.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 5/28/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import UIKit
import CoreData
import CoreLocation

extension Message {

    //Location Attributes
    @NSManaged var altitude: NSNumber?
    @NSManaged var course: NSNumber?
    @NSManaged var horizontalAccuracy: NSNumber?
    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var speed: NSNumber?
    @NSManaged var timestamp: NSDate?
    @NSManaged var verticalAccuracy: NSNumber?

    //MSG Attributtes
    @NSManaged var senderName: String?
    @NSManaged var text: String?
    @NSManaged var timeDropped: NSDate?
    @NSManaged var timeLimit: NSNumber?
    @NSManaged var senderuuid: String?
    @NSManaged var votevalue: NSNumber?
    @NSManaged var recorduuid: String?
    @NSManaged var viewedOther: NSNumber?//stored as a 0 or 1 1 == seen/true
    @NSManaged var hasVoted: NSNumber?//stored as a -1,0,1 zero is no vote
    @NSManaged var addressStr: String?//stores an address like this "\(locality!), \(thoroughfare!), \(country!)"
    //@NSManaged var creatorUniqueID: String //used to test messages against each other, allows multiple people to have the same name
    
    func initFromLocation(location: CLLocation) {
        self.latitude           = location.coordinate.latitude
        self.longitude          = location.coordinate.longitude
        self.altitude           = location.altitude
        self.timestamp          = location.timestamp
        
        self.horizontalAccuracy = location.horizontalAccuracy > 0.0 ? location.horizontalAccuracy : 0.0
        self.verticalAccuracy   = location.verticalAccuracy > 0.0 ? location.verticalAccuracy : 0.0
        self.speed              = location.speed > 0.0 ? location.speed : 0.0
        self.course             = location.course > 0.0 ? location.course : 0.0
    }
    
    
    func cdlocation() -> CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: self.latitude!.doubleValue, longitude: self.longitude!.doubleValue),
            altitude: self.altitude!.doubleValue,
            horizontalAccuracy: self.horizontalAccuracy!.doubleValue,
            verticalAccuracy: self.verticalAccuracy!.doubleValue,
            course: self.course!.doubleValue,
            speed: self.speed!.doubleValue,
            timestamp: self.timestamp!
        )
    }
    
    
    func calculate() -> Bool{
        //in essence: timedropped + timelimit = timeDeadline; timeCurrent - timeDeadline = timeLeft
        //convert timeleft to days hours
        
        let timeDropped = self.timeDropped!
        
        let timeDeadline:NSDate = timeDropped.dateByAddingTimeInterval(Double(timeLimit!))
        
        let timeCurrent: NSDate = NSDate()
        
        let timeLeft = timeDeadline.timeIntervalSinceDate(timeCurrent)
        
        if timeLeft >= 0 {
            print(timeLeft)
            return true//the message is still alive
        } else{
            return false// tis is dead rip in pease
        }
    }
}

