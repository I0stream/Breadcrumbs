//
//  CrumbMessage.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 4/15/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class CrumbMessage{
    //MARK: Properties
    
    var senderuuid: String
    var votes: Int?
    var text: String
    var senderName: String
    var location: CLLocation
    var timeDropped: Date
    var timeLimit: Int
    var uRecordID: String?//the id of the unique record
    var viewedOther: Int?
    var hasVoted: Int?
    //var addressStr: String?
    //var commentsArr: [Comment]//array of comments
    
    
    
    //MARK: Initialization
    init?(text: String, senderName: String, location: CLLocation, timeDropped: Date
        , timeLimit: Int, senderuuid: String, votes: Int?){
        self.text = text
        self.senderName = senderName
        self.location = location
        self.timeDropped = timeDropped
        self.timeLimit = timeLimit
        self.senderuuid = senderuuid
        self.votes = votes
        //self.commentsArr = []
        //test if empty; see if the message is only whitespace cause that would be annoying
        if text.isEmpty || senderName.isEmpty {
            return nil
        }
    }
    
   /* func convertCoordinatesToAddress(locationCoor: CLLocation, completion: (answer: String?) -> Void) {// used in load others crumbs and
        //in write crumbs aka this value is completely local for both types of crumbs, only stored in cd and is never sent or recieved from cloud
        let geoCoder = CLGeocoder()
        
        geoCoder.reverseGeocodeLocation(locationCoor, completionHandler: {(placemarks, error) -> Void in
            if (error != nil) {
                print("Reverse geocoder failed with an error" + error!.localizedDescription)
                completion(answer: nil)
            } else if placemarks!.count > 0 {
                let pm = placemarks![0] as CLPlacemark
                completion(answer: self.displayLocationInfo(pm))//store return value into crumb then crumb into cd only after done
            } else {
                print("Problems with the data received from geocoder.")
                completion(answer: nil)
            }
        })
    }*/
    
    func displayLocationInfo(_ placemark: CLPlacemark?) -> String?{//used in convertCoordinatesToAddress for reasons
        if let containsPlacemark = placemark
        {
            let locality = (containsPlacemark.locality != nil) ? containsPlacemark.locality : ""
            let thoroughfare = (containsPlacemark.thoroughfare != nil) ? containsPlacemark.thoroughfare : ""
            //let country = (containsPlacemark.country != nil) ? containsPlacemark.country : ""
            
            return "\(locality!), \(thoroughfare!)"//, \(country!)"
        } else {
            return nil
        }
        
    }
    
    func calculate() -> Double{//calculates the time remaining in hours for a shortend use in cells
        //in essence: timedropped + timelimit = timeDeadline; timeCurrent - timeDeadline = timeLeft
        //convert timeleft to days hours 
        
        let timeDeadline:Date = timeDropped.addingTimeInterval(Double(timeLimit) * 3600)// date crumbs dies
        
        let timeCurrent: Date = Date()//current date and time
        
        var timeLeft = timeCurrent.timeIntervalSince(timeDeadline) / 3600//time remaining in hours
        
        timeLeft = round(timeLeft * -1)// since its the future we multiply by -1 and round off the %hours
        
        return timeLeft//returns
    }
    
    //MARK: countdown timer test
    
    func countdownTimerSpecific()-> Int{//time remaining in seconds; name is pretty shit; they were ment to be test names
        
        //convert timeleft to days hours
        
        let timeDeadline:Date = timeDropped.addingTimeInterval(Double(timeLimit) * 3600)// date crumbs dies
        
        let timeCurrent: Date = Date()//current date and time
        
        let timeLeftSeconds = -Int(timeCurrent.timeIntervalSince(timeDeadline))//time remaining in seconds
        
        return timeLeftSeconds// returnstimesec
    }
    
    
    func dateOrganizer() -> String{//short style dates for timeposted
        let dateformatter = DateFormatter()
        
        dateformatter.dateStyle = DateFormatter.Style.short
        
        dateformatter.timeStyle = DateFormatter.Style.short
        
        let timeorganized = dateformatter.string(from: timeDropped)

        return timeorganized
    }
    
    func dateToStringFormat() -> String{
        let calendar = Calendar.current
        let components = (calendar as NSCalendar).components([.day , .month , .year], from: timeDropped)
        
        //let year =  components.year
        let month = components.month
        let day = components.day
        var StringDate = ""
        
        switch (month!) {
        case 1:
            StringDate = "Jan"
        case 2:
            StringDate = "Feb"
        case 3:
            StringDate = "Mar"
        case 4:
            StringDate = "Apr"
        case 5:
            StringDate = "May"
        case 6:
            StringDate = "Jun"
        case 7:
            StringDate = "Jul"
        case 8:
            StringDate = "Aug"
        case 9:
            StringDate = "Sep"
        case 10:
            StringDate = "Oct"
        case 11:
            StringDate = "Nov"
        case 12:
            StringDate = "Dec"
        default:
            StringDate = dateOrganizer()
        }
        StringDate = StringDate + " \(day!)"
        
        return StringDate
    }

    func timeRelative() -> String{//a function that returns various forms of time from seconds to months
        var newdate: String = ""
        
        let test = -timeDropped.timeIntervalSinceNow
        
        switch test {
        case 0 ..< 60://60 second
            newdate = "a few seconds ago"
            
        case 60 ..< 119://minute
            
            newdate = "\(-Int(timeDropped.timeIntervalSinceNow/60)) minute ago"
        case 120 ..< 3600://minutes
            
            newdate = "\(-Int(timeDropped.timeIntervalSinceNow/60)) minutes ago"
            
        case 3600 ..< 7119://hour
            newdate = "\(-Int(timeDropped.timeIntervalSinceNow/3600)) hour ago"
            
        case 7200 ..< 86400://hours
            newdate = "\(-Int(timeDropped.timeIntervalSinceNow/3600)) hours ago"
            
        case 86400 ..< 31556900://days
            newdate = dateToStringFormat()//sept 5,4,3,etc
            //
        case let x where x >= 31556900:
            newdate = dateOrganizer()
        default:
            newdate = "some time ago"
        }
        return newdate
    }
    /*case 60 ..< 3600://minutes
     
     newdate = "\(-Int(timeDropped.timeIntervalSinceNow/60)) minutes ago"
     
     case 3600 ..< 86400://hours
     newdate = "\(-Int(timeDropped.timeIntervalSinceNow/3600)) hours ago"
     */
    
}

//gonna get da monie doe $$, but gov's fairness tax gonna take it away :((
//can't make profit cause it would be immoral and unfair for lesser men :'(
//guess who is reading ayn rand :^)
