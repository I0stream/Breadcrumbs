//
//  HelperFunctions.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 8/15/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import CoreData
import UIKit
import CloudKit


class Helper{
    
    let NSUserData = UserDefaults.standard
    
    func getmoc() -> NSManagedObjectContext{
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let moc = appDelegate?.CDStack.mainContext

        
        //let moc = (UIApplication.shared.delegate as! AppDelegate).CDStack.mainContext
        return moc!
    }
    //MARK: LOAD
    func loadIcloudMessageToCoreData(_ query: CKQuery) {// used in appdelegate and signinviewcontroller
        //get public database object
             
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        
        publicData.perform(query, inZoneWith: nil) { results, error in
            if error == nil{ // There is no error
                for cmsg in results! {
                    
                    let dbtext = cmsg["text"] as! String
                    let dbsenderName = cmsg["senderName"] as! String
                    let dblocation = cmsg["location"] as! CLLocation
                    let dbtimedropped = cmsg["timeDropped"] as! Date
                    let dbtimelimit = cmsg["timeLimit"] as! Int
                    let dbvotes = cmsg["votes"] as! Int
                    let dbsenderuuid = cmsg["senderuuid"] as! String
                    let uniqueRecordID = cmsg.recordID.recordName
                    //let reportValue = cmsg["reportValue"] as! Int
                    //let comments = cmsg["referenceComments"]
                    //print(comments as Any)
                    
                    let loadedMessage = CrumbMessage(text: dbtext, senderName: dbsenderName, location: dblocation, timeDropped: dbtimedropped, timeLimit: dbtimelimit, senderuuid: dbsenderuuid, votes: dbvotes)
                    
                    //commentsArr
                    //loadedMessage?.commentsArr = comments
                    loadedMessage!.uRecordID = uniqueRecordID
                    loadedMessage!.hasVoted = 0
                    
                    let testID = loadedMessage?.senderuuid != self.NSUserData.string(forKey: "recordID")!
                    
                    //print(loadedMessage?.senderName as Any)
                    //print(loadedMessage?.location.description as Any)
                    //print(loadedMessage!.calculate())
                    
                    if (loadedMessage!.calculate() > 0) && testID{
                        
                        DispatchQueue.main.async(execute: { () -> Void in

                            //TESTS IF LOADED MSG IS IN COREDATA IF NOT THEN STORES IT BRAH
                            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Message")
                            let cdPredicate = NSPredicate(format: "recorduuid == %@", loadedMessage!.uRecordID!)
                            fetchRequest.predicate = cdPredicate
                            
                            do {
                                if let fetchResults = try self.getmoc().fetch(fetchRequest) as? [Message]{
                                    if fetchResults.isEmpty{//keep reading tuts man your having mucho trouble-o
                                        //loadedMessage!.convertCoordinatesToAddress((loadedMessage!.location), completion: { (answer) in
                                        
                                        //loadedMessage!.addressStr = answer!
                                        
                                        self.saveToCoreData(loadedMessage!)
                                        if UIApplication.shared.applicationState != UIApplicationState.active{
                                            AppDelegate().notify()//if this is how we will do it, we must have a seen and unseen marker
                                        }
                                        
                                        
                                        // })
                                        
                                        //set value to limit crumbs in area like let newvalue =  NSUserData.IntForKey("limitarea")! + 1
                                        // self.NSUserData.setValue(, forKey: "limitArea")
                                        //test in write crumb message
                                        //reset in appdelegates
                                    }
                                }
                            } catch{//there is an error
                                let fetchError = error as NSError
                                print(fetchError)
                            }
                        
                        })
                    }
                    else if loadedMessage!.calculate() <= 0//if message is past due delete the ckufer
                    {
                        //delete, I think
                        print("delete crumb")
                        print(loadedMessage!)
                        
                        let yum = CKRecordID(recordName: (loadedMessage?.uRecordID)!)
                        self.cloudKitDeleteCrumb(yum)
                        
                        print("Finished request delete \(cmsg)")
                    }else{break}
                }
            }else {
                print(error.debugDescription)//print error
            }
        }

    }

    //tests if messages have been recently recieved in teh area  limited to 6/IS UNTESTED/
    func testStoredMsgsInArea(_ usersLocation: CLLocation){
             var crumbmessagestotest = [Int]()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        let entityDescription = NSEntityDescription.entity(forEntityName: "Message", in: getmoc())
        
        fetchRequest.entity = entityDescription
        
        do {
            let fetchedmsgsCD = try getmoc().fetch(fetchRequest) as! [Message]
            
            var i = 0
            while  i <= (fetchedmsgsCD.count - 1){//loops through all of coredata store
                
                let msgloc = fetchedmsgsCD[i].cdlocation() as CLLocation
                
                let nearby = msgloc.distance(from: usersLocation)// does not take into account high rise buildings
                if nearby < 50{//is within x meters of users loc
                    
                    let value = 1
                    crumbmessagestotest += [value]
                        
                    }
                i += 1
            }
        }catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        
        if crumbmessagestotest.count < 7{//limits to seven per 50 meters, i think, still a wip
            AppDelegate().NSUserData.setValue(0, forKey: "limitArea")
        } else{
            AppDelegate().NSUserData.setValue(1, forKey: "limitArea")

        }

    }
    
    //used in yourTableView and othersTableView
    //If true load myUsers, if false loadOthers also remember to add to crumbmessages[]
    func loadCoreDataMessage(_ typeOfCrumbLoading:Bool) -> [CrumbMessage]? {
    
        var crumbmessagestoload = [CrumbMessage]()
        
        let fetchRequest: NSFetchRequest<Message> = Message.fetchRequest()

        
        //let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        let entityDescription = NSEntityDescription.entity(forEntityName: "Message", in: getmoc())
        
        fetchRequest.entity = entityDescription
        
        do {
            let fetchedmsgsCD = try getmoc().fetch(fetchRequest)
            let Usersendername = NSUserData.string(forKey: "recordID")!//user user unique id
            
            var i = 0
            while  i <= (fetchedmsgsCD.count - 1){//loops through all of coredata store
                
                if typeOfCrumbLoading == true{//load your CrumbMessages
                    if fetchedmsgsCD[i].senderuuid! == Usersendername {//compares sendername of user's to msgs and returns user's msgs
                        let fmtext = fetchedmsgsCD[i].text! as String
                        let fmsenderName = fetchedmsgsCD[i].senderName! as String
                        let fmlocation = fetchedmsgsCD[i].cdlocation() as CLLocation
                        let fmtimedropped = fetchedmsgsCD[i].timeDropped! as Date
                        let fmtimelimit = fetchedmsgsCD[i].timeLimit as! Int
                        let fmsenderuuid = fetchedmsgsCD[i].senderuuid! as String
                        let fmvotes = fetchedmsgsCD[i].votevalue as! Int
                        //let fmaddressStr = fetchedmsgsCD[i].addressStr as String!
                        
                        let fmCrumbMessageYours = CrumbMessage(text: fmtext, senderName: fmsenderName, location: fmlocation, timeDropped: fmtimedropped, timeLimit: fmtimelimit, senderuuid: fmsenderuuid, votes: fmvotes)
                        
                        fmCrumbMessageYours?.hasVoted = fetchedmsgsCD[i].hasVoted! as Int
                        // ]\\commentsArr commentsArr
                        
                        fmCrumbMessageYours?.uRecordID = fetchedmsgsCD[i].recorduuid! as String
                        //fmCrumbMessageYours?.addressStr = fmaddressStr
                        crumbmessagestoload += [fmCrumbMessageYours!]
                        
                    }
                }
                else if typeOfCrumbLoading == false{//load others CrumbMessages
                    if fetchedmsgsCD[i].senderuuid! != Usersendername{//compares sendername of users and returns others msgs
                        let fmtext = fetchedmsgsCD[i].text! as String
                        let fmsenderName = fetchedmsgsCD[i].senderName! as String
                        let fmlocation = fetchedmsgsCD[i].cdlocation() as CLLocation
                        let fmtimedropped = fetchedmsgsCD[i].timeDropped! as Date
                        let fmtimelimit = fetchedmsgsCD[i].timeLimit as! Int
                        let fmsenderuuid = fetchedmsgsCD[i].senderuuid! as String
                        let fmvote = fetchedmsgsCD[i].votevalue! as Int
                        let fmrecorduuid = fetchedmsgsCD[i].recorduuid! as String
                        let fmhasVoted = fetchedmsgsCD[i].hasVoted as! Int
                        let fmviewedOther = fetchedmsgsCD[i].viewedOther as! Int
                        //let fmcommentsArr = fetchedmsgsCD[i].comments! as [Comment]
                        
                        let fmCrumbMessageOther = CrumbMessage(text: fmtext, senderName: fmsenderName, location: fmlocation, timeDropped: fmtimedropped, timeLimit: fmtimelimit, senderuuid: fmsenderuuid, votes: fmvote)
                        
                        //fmCrumbMessageOther?.commentsArr = fmcommentsArr
                        
                        fmCrumbMessageOther?.uRecordID = fmrecorduuid
                        fmCrumbMessageOther?.hasVoted = fmhasVoted
                        fmCrumbMessageOther?.viewedOther = fmviewedOther
                        //fmCrumbMessageOther?.addressStr = fmaddressStr
                        
                        crumbmessagestoload += [fmCrumbMessageOther!]
                    }
                }
                i += 1
            }
        }catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return crumbmessagestoload
    }
    
    
    
    
    
    //MARK: SAVE
    func saveToCoreData(_ crumbmessage: CrumbMessage){
        //create Message: NSManagedObject
        let messageMO = NSEntityDescription.insertNewObject(forEntityName: "Message", into: getmoc()) as! BreadCrumbs.Message
        
        messageMO.setValue(crumbmessage.text, forKey: "text")
        messageMO.setValue(crumbmessage.senderName, forKey: "senderName")
        messageMO.setValue(crumbmessage.timeDropped, forKey: "timeDropped")
        messageMO.setValue(crumbmessage.timeLimit, forKey: "timeLimit")
        messageMO.initFromLocation(crumbmessage.location)
        messageMO.setValue(crumbmessage.senderuuid, forKey: "senderuuid")
        messageMO.setValue(crumbmessage.votes, forKey: "votevalue")
        messageMO.setValue(crumbmessage.uRecordID, forKey: "recorduuid")
        messageMO.setValue(0, forKey: "viewedOther")
        messageMO.setValue(0, forKey: "hasVoted")
        //messageMO.setValue(crumbmessage.addressStr, forKey: "addressStr")
        
        do {
            try messageMO.managedObjectContext?.save()
            print("a message has been loaded and stored into coredata")
            
            if /*usernotification value == true*/ true{
                //notify user a new msg is here with notification
                AppDelegate().notify()
            }
            
            //print("updated and stored more butts")
        } catch {
            print(error)
        }
    }
    
    
    //MARK: DELETE
    func cloudKitDeleteCrumb(_ currentRecordID: CKRecordID){//should only be used by timelimit checkers/load and store
        
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        
        publicData.delete(withRecordID: currentRecordID, completionHandler: { (record, error) in
            if error == nil{
                print("record is deleted from cloudkit")
            }else{
                print("error in cloudkitdeletecrumb in helperfunctions")
                print(error.debugDescription)
                
                //alert user delete failed
            }
        })
        
        //save?
    }
    
    func coreDataDeleteCrumb(_ cdrecorduuid: String, manx: NSManagedObjectContext){
        let cdPredicate = NSPredicate(format: "recorduuid == %@", cdrecorduuid)

    
        var fetchRequest: NSFetchRequest<Message>
        
        if #available(iOS 10.0, OSX 10.12, *) {
            fetchRequest = Message.fetchRequest()
        } else {
            fetchRequest = NSFetchRequest(entityName: "Message")
        }
        fetchRequest.predicate = cdPredicate
        do {
            let fetchedEntities = try manx.fetch(fetchRequest)
            if let entityToDelete = fetchedEntities.first {
                manx.delete(entityToDelete)
                print("record is deleted from coredata")
            }
        } catch {
            // Do something in response to error condition
            print("something went wrong")
            print(error)
        }
        do {
            try manx.save()
        } catch {
            print(error)
            // Do something in response to error condition
        }
    }
    
    


    
    //Coredata Needs
    
    
    //Core Data Saving support
    func saveContext () {
             if getmoc().hasChanges {
            do {
                try getmoc().save()
            } catch {
                
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    
    func loadComments(uniqueRecordID: String) -> [CommentShort]{//loads from coredata
             
        var commentsToLoad = [CommentShort]()
        
        
        var fetchRequest: NSFetchRequest<Comment>
        if #available(iOS 10.0, OSX 10.12, *) {
            fetchRequest = Comment.fetchRequest()
        } else {
            fetchRequest = NSFetchRequest(entityName: "Comment")
        }
        let entityDescription = NSEntityDescription.entity(forEntityName: "Comment", in: getmoc())
        
        fetchRequest.entity = entityDescription
        
        do {
            let fmComment = try getmoc().fetch(fetchRequest) 
            //commentsToLoad
            var i = 0
            while  i <= (fmComment.count - 1){//loops through all of coredata store
                if fmComment[i].message?.recorduuid == uniqueRecordID {//compares sendername of user's to msgs and returns user's msgs

                    let fmtext = fmComment[i].text! as String
                    let fmsenderName = fmComment[i].username! as String
                    let fmtimeSent = fmComment[i].timeSent! as Date
                    let fmComment = CommentShort(username: fmsenderName, text: fmtext, timeSent: fmtimeSent)
                
                    // ]\\commentsArr commentsArr
                    //fmCrumbMessageYours?.addressStr = fmaddressStr
                    commentsToLoad += [fmComment]
                }
                i += 1
            }
        }catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return commentsToLoad
    }
    //MARK: updating
    
    
    //used in appdelegate in application did become active /IS UNTESTED/
    func updateTableViewVoteValues(){//checks for all msgs, need to do it only for alive msgs
        
        //grab all crumbs within cd that are alive
        // ******************************************
        var RecordIDsToTest = [String]()//takes ids of stored alive crumbs
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        let entityDescription = NSEntityDescription.entity(forEntityName: "Message", in: getmoc())
        
        fetchRequest.entity = entityDescription
        
        do {
            let fetchedmsgsCD = try getmoc().fetch(fetchRequest) as! [Message]
            var i = 0
            
            while  i <= (fetchedmsgsCD.count - 1){//loops through all of coredata store
                if fetchedmsgsCD[i].calculate() == true {//compares sendername of user's to msgs and returns user's msgs
                    let msgToUpdateRecordID = fetchedmsgsCD[i].recorduuid! as String
                    
                    RecordIDsToTest += [msgToUpdateRecordID]
                    
                }
                i += 1
            }
        }catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        
        //take alive crumbs and make an updater call to ck, update votevalue in alive crumbs
        // ****************************************** //
        
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        
        for id in RecordIDsToTest{
            let ckidToTest = CKRecordID(recordName: id)//the message record id to fetch from cloudkit
            
            publicData.fetch(withRecordID: ckidToTest, completionHandler: {record, error in
                if error == nil{
                    let newvalue = record!.object(forKey: "votes") as! Int
                    
                    //update cd with new vote values
                    // *******************************************/
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.updateCdVote(id, voteValue: newvalue)
                    })
                }else{
                    print(error.debugDescription)
                }
            })
        }
    }
    
    //used above, takes id and new vote value and updates the alive message. I think
    func updateCdVote(_ cdrecorduuid: String, voteValue: Int){
        let predicate = NSPredicate(format: "recorduuid == %@", cdrecorduuid)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Message")
        fetchRequest.predicate = predicate
        
        do {// change it, it not work y?
            let fetchedMsgs = try getmoc().fetch(fetchRequest) as! [Message]
            
            fetchedMsgs.first?.setValue(voteValue, forKey: "votevalue")
            
            do {// save it!
                try getmoc().save()
                print("did save cd vote")
                
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
    }
    
    
    func updateTableViewcomments(){
             //grab all crumbs within cd that are alive
        // ******************************************
        var RecordIDsToTest = [String]()//takes ids of stored alive crumbs
        
        var fetchRequest: NSFetchRequest<Message>
        
        if #available(iOS 10.0, OSX 10.12, *) {
            fetchRequest = Message.fetchRequest()
        } else {
            fetchRequest = NSFetchRequest(entityName: "Message")
        }
        
        let entityDescription = NSEntityDescription.entity(forEntityName: "Message", in: getmoc())
        fetchRequest.entity = entityDescription
        
        do {
            let fetchedmsgsCD = try getmoc().fetch(fetchRequest)//load alive messages from cd
            var i = 0
            
            while  i <= (fetchedmsgsCD.count - 1){//loops through all of coredata store
                if fetchedmsgsCD[i].calculate() == true {//compares sendername of user's to msgs and returns user's msgs
                    let msgToUpdateRecordID = fetchedmsgsCD[i].recorduuid! as String
                    
                    RecordIDsToTest += [msgToUpdateRecordID]
                }
                i += 1
            }
        }catch {
            print(error.localizedDescription)
        }
        
        //take alive crumbs and make an updater call to ck
        
        for id in RecordIDsToTest{//takes ids and loads comments from ck
            let ckidToTest = CKRecordID(recordName: id)//the message record id to fetch from cloudkit
            
            let ref = CKReference(recordID: ckidToTest, action: CKReferenceAction.deleteSelf)
            
            let predicate = NSPredicate(format: "ownerReference == %@", ref)//fetches all comments associated with this msg
            let query = CKQuery(recordType: "Comment", predicate: predicate)
            
            let container = CKContainer.default()
            let publicData = container.publicCloudDatabase
            
            publicData.perform(query, inZoneWith: nil) { results, error in//querys to database for matching comments
                if error == nil{ // There is no error
                    for ckComment in results! {//make comment
                        let user = ckComment.value(forKey: "userName") as! String
                        let text = ckComment.value(forKey: "text") as! String
                        let time = ckComment.value(forKey: "timeSent") as! Date
                        let recorduuid = ckComment.recordID.recordName
                        let com = CommentShort(username: user, text: text, timeSent: time)
                        com.recorduuid = recorduuid
                        
                        DispatchQueue.main.async(execute: { () -> Void in//test to see if msg is in core data
                            
                            //TESTS IF LOADED comment IS IN COREDATA IF NOT THEN STORES IT BRAH
                            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Comment")
                            let cdPredicate = NSPredicate(format: "recorduuid == %@", recorduuid)
                            fetchRequest.predicate = cdPredicate
                            do {
                                if let fetchResults = try self.getmoc().fetch(fetchRequest) as? [Comment]{
                                    if fetchResults.isEmpty{
                                        //save comments to cd
                                        self.saveCommentToCD(comment: com, recordID: id)//Saves to coredata
                                    }
                                }
                            } catch{//there is an error
                                let fetchError = error as NSError
                                print(fetchError.localizedDescription)
                            }
                        })
                    }
                } else {
                    print(error.debugDescription)//print error
                }
            }
        }
    }
    
    func saveCommentToCD(comment: CommentShort, recordID: String){
        
        let commentMO = NSEntityDescription.insertNewObject(forEntityName: "Comment", into: getmoc()) as! BreadCrumbs.Comment
        
        let predicate = NSPredicate(format: "recorduuid == %@", recordID)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Message")
        fetchRequest.predicate = predicate
        do {// change it, it not work y?
            let fetchedMsgs = try getmoc().fetch(fetchRequest) as! [Message]
            
            let ComMessage = fetchedMsgs[0]
            
            commentMO.setValue(comment.text, forKey: "text")
            commentMO.setValue(comment.username, forKey: "username")
            commentMO.setValue(comment.timeSent, forKey: "timeSent")
            //recorduuid
            commentMO.setValue(comment.recorduuid, forKey: "recorduuid")
            commentMO.message = ComMessage
            
            
            do {
                try commentMO.managedObjectContext?.save()
                print("new comment saved to coredata")
            } catch {
                print(error)
                print("cd error in create crumbs")
                
            }
        } catch {
            print(error)
        }
        
    }
    
    func crumbVote(_ hasvoted: Int, crumb: CrumbMessage) {//what happens when a vote conflicts between cd and ck?, this just does ck atm
        voteCKVote(crumb)
        voteCoreDataVote(hasvoted, crumb: crumb)
    }
    
    //updates ck with new value
    func voteCKVote(_ crumb: CrumbMessage){
        
        let recorduuid = CKRecordID(recordName: (crumb.uRecordID)!)
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        
        publicData.fetch(withRecordID: recorduuid, completionHandler: {record, error in
            if error == nil{
                let newvalue = (crumb.votes)!
                
                record!.setValue(newvalue as CKRecordValue?, forKey: "votes")
                
                publicData.save(record!, completionHandler: {theRecord, error in
                    if error == nil{
                        print("saved version")
                        
                    }else{
                        
                        print("local desc save: \(error?.localizedDescription) \n")
                    }
                })
            }else{
                print(recorduuid)
                print("local desc fetch: \(error?.localizedDescription) \n")
            }
        })
    }
    
    
    //updates coredata with the new value
    func voteCoreDataVote(_ hasvoted: Int, crumb: CrumbMessage){
             let cdrecorduuid = (crumb.uRecordID)!
        
        let predicate = NSPredicate(format: "recorduuid == %@", cdrecorduuid)
        
        var fetchRequest: NSFetchRequest<Message>
        
        if #available(iOS 10.0, OSX 10.12, *) {
            fetchRequest = Message.fetchRequest()
        } else {
            fetchRequest = NSFetchRequest(entityName: "Message")
        }
        
        fetchRequest.predicate = predicate
        
        do {// change it, it not work y?
            let fetchedMsgs = try getmoc().fetch(fetchRequest)
            
            fetchedMsgs.first?.setValue((crumb.votes!), forKey: "votevalue")
            fetchedMsgs.first?.setValue(hasvoted, forKey: "hasVoted")
            do {// save it!
                try getmoc().save()
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
    }
    /*
    //updates ck with new value
    func voteCKVote(_ recorduuid: CKRecordID){
        
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        
        publicData.fetch(withRecordID: recorduuid, completionHandler: {record, error in
            if error == nil{
                let newvalue = self.theVoteValueToBeStored + (self.viewbreadcrumb?.votes)!
                
                record!.setObject(newvalue as CKRecordValue?, forKey: "votes")
                
                publicData.save(record!, completionHandler: {theRecord, error in
                    if error == nil{
                        print("saved version")
                    }else{
                        print(error.debugDescription)
                    }
                })
            }else{
                print(error.debugDescription)
            }
        })
    }
    
    //updates coredata with the new value
    func voteCoreDataVote(_ cdrecorduuid: String, counter: Int){
        
        let predicate = NSPredicate(format: "recorduuid == %@", cdrecorduuid)
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Message")
        fetchRequest.predicate = predicate
        
        do {// change it, it not work y?
            let fetchedMsgs = try helperFunctions.getmoc().fetch(fetchRequest) as! [Message]
            
            fetchedMsgs.first?.setValue(theVoteValueToBeStored, forKey: "votevalue")
            fetchedMsgs.first?.setValue(counter, forKey: "hasVoted")
            do {// save it!
                try helperFunctions.getmoc().save()
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
    }*/
}
