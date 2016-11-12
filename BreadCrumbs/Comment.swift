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

class Comment {
    
    let username: String
    let text: String
    let helperFunctions = Helper()
    
    init(username: String, text: String) {
        self.username = username
        self.text = text
        //time posted
    }
    
    
    
    func saveAndAddNewComment(uniqueRecordID: String) {
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
    
}
