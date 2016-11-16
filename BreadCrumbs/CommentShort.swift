//
//  Comments.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 10/28/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

class CommentShort {
    
    let username: String
    let text: String
    let timeSent: Date
    
    init(username: String, text: String, timeSent: Date) {
        self.username = username
        self.text = text
        self.timeSent = timeSent
        //time posted
    }
    
    
   
    
    func dateToStringFormat() -> String{
        let calendar = Calendar.current
        let components = (calendar as NSCalendar).components([.day , .month , .year], from: timeSent)
        
        //let year =  components.year
        let month = components.month
        let day = components.day
        var StringDate = ""
        
        switch month! {
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
        StringDate = StringDate + " \(day)"
        
        return StringDate
    }
    
    func saveAndAddNewComment(_ uniqueRecordID: String) {
        //saveToCD(uniqueRecordID)
        //saveToCK(uniqueRecordID)
    }
    /*func saveToCK(uniqueRecordID: String){
        let container = CKContainer.defaultContainer()
        let publicData = container.publicCloudDatabase
        
        let recordid = CKRecordID(recordName: uniqueRecordID)
        
        publicData.fetchRecordWithID(recordid, completionHandler: {record, error in
            if error == nil{
                
                
                record!.setObject(newvalue, forKey: "votes")
                
                publicData.saveRecord(record!, completionHandler: {theRecord, error in
                    if error == nil{
                        print("saved version")
                    }else{
                        print(error)
                    }
                })
            }else{
                print(error)
            }
        })
    }*/
    
    /*func saveToCD(uniqueRecordID: String){
        
        let predicate = NSPredicate(format: "recorduuid == %@", uniqueRecordID)
            
        let fetchRequest = NSFetchRequest(entityName: "Message")
        fetchRequest.predicate = predicate
            
        do {// change it, it not work y?
            let fetchedMsgs = try helperFunctions.moc.executeFetchRequest(fetchRequest) as! [Message]
            
            let comment = Comment(username: username, text: text)
            
            fetchedMsgs.first?.setValue(comment, forKey: "Comments")
            do {// save it!
                try helperFunctions.moc.save()
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
    }*/
    func timeRelative() -> String{//a function that returns various forms of time from seconds to months
        var newdate: String = ""
        
        let test = -timeSent.timeIntervalSinceNow
        
        switch test {
        case 0 ..< 60://60 second
            newdate = "a few seconds ago"
        case 60 ..< 3600://minutes
            
            newdate = "\(-Int(timeSent.timeIntervalSinceNow/60)) minutes ago"
            
        case 3600 ..< 86400://hours
            newdate = "\(-Int(timeSent.timeIntervalSinceNow/3600)) hours ago"
            
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
    func dateOrganizer() -> String{//short style dates for timeposted
        let dateformatter = DateFormatter()
        
        dateformatter.dateStyle = DateFormatter.Style.short
        
        dateformatter.timeStyle = DateFormatter.Style.short
        
        let timeorganized = dateformatter.string(from: timeSent)
        
        return timeorganized
    }
}
