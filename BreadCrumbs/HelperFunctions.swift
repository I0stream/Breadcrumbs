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
    
    let NSUserData = NSUserDefaults.standardUserDefaults()
    
    //MARK: LOAD
    func loadIcloudMessageToCoreData(query: CKQuery) {// used in appdelegate and signinviewcontroller
        //get public database object
        let container = CKContainer.defaultContainer()
        let publicData = container.publicCloudDatabase
        
        publicData.performQuery(query, inZoneWithID: nil) { results, error in
            if error == nil{ // There is no error
                for cmsg in results! {
                    
                    let dbtext = cmsg["text"] as! String
                    let dbsenderName = cmsg["senderName"] as! String
                    let dblocation = cmsg["location"] as! CLLocation
                    let dbtimedropped = cmsg["timeDropped"] as! NSDate
                    let dbtimelimit = cmsg["timeLimit"] as! Int
                    let dbvotes = cmsg["votes"] as! Int
                    let dbsenderuuid = cmsg["senderuuid"] as! String
                    let uniqueRecordID = cmsg.recordID.recordName
                    //let reportValue = cmsg["reportValue"] as! Int
                                        
                    let loadedMessage = CrumbMessage(text: dbtext, senderName: dbsenderName, location: dblocation, timeDropped: dbtimedropped, timeLimit: dbtimelimit, senderuuid: dbsenderuuid, votes: dbvotes)
                    
                    loadedMessage!.uRecordID = uniqueRecordID
                    
                    let timeToDelete: NSDate = (loadedMessage?.timeDropped.dateByAddingTimeInterval(NSTimeInterval(dbtimelimit)))!
                    let currentTime = NSDate.init()
                    
                    let testTime = currentTime.compare(timeToDelete) == NSComparisonResult.OrderedDescending
                    let testID = loadedMessage?.senderuuid != self.NSUserData.stringForKey("recordID")!
                    if testTime && testID{
                        
                        //TESTS IF LOADED MSG IS IN COREDATA IF NOT THEN STORES IT BRAH
                        let fetchRequest = NSFetchRequest(entityName: "Message")
                        let cdPredicate = NSPredicate(format: "recorduuid == %@", loadedMessage!.uRecordID!)
                        fetchRequest.predicate = cdPredicate
                        
                        do {
                            if let fetchResults = try self.moc.executeFetchRequest(fetchRequest) as? [Message]{
                                if fetchResults.isEmpty{//keep reading tuts man your having mucho trouble-o
                                    loadedMessage!.convertCoordinatesToAddress((loadedMessage!.location), completion: { (answer) in
                                        
                                        loadedMessage!.addressStr = answer!
                                        
                                        self.saveToCoreData(loadedMessage!)
                                        if UIApplication.sharedApplication().applicationState != UIApplicationState.Active{
                                            self.pingNotifications()//if this is how we will do it, we must have a seen and unseen marker
                                        }
                                        
                                        
                                    })
                                    
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
                    }else if loadedMessage!.calculate() <= 0 //|| Report >= 7//if message is past due delete the ckuffer
                    {
                        //delete, I think
                        print("delete crumb")
                        dispatch_group_enter(AppDelegate().myGroup)
                        self.cloudKitDeleteCrumb(CKRecordID(recordName: (loadedMessage?.uRecordID)!))
                        print("Finished request delete \(cmsg)")
                        dispatch_group_leave(AppDelegate().myGroup)
                    }else{break}
                }
            }else {
                print(error)//print error
            }
        }

    }

    //tests if messages have been recently recieved in teh area  limited to 6/IS UNTESTED/
    func testStoredMsgsInArea(usersLocation: CLLocation){
        var crumbmessagestotest = [Int]()
        
        let fetchRequest = NSFetchRequest()
        let entityDescription = NSEntityDescription.entityForName("Message", inManagedObjectContext: moc)
        
        fetchRequest.entity = entityDescription
        
        do {
            let fetchedmsgsCD = try moc.executeFetchRequest(fetchRequest) as! [Message]
            
            var i = 0
            while  i <= (fetchedmsgsCD.count - 1){//loops through all of coredata store
                
                let msgloc = fetchedmsgsCD[i].cdlocation() as CLLocation
                
                let nearby = msgloc.distanceFromLocation(usersLocation)// does not take into account high rise buildings
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
    func loadCoreDataMessage(typeOfCrumbLoading:Bool) -> [CrumbMessage]? {        
        var crumbmessagestoload = [CrumbMessage]()
        
        let fetchRequest = NSFetchRequest()
        let entityDescription = NSEntityDescription.entityForName("Message", inManagedObjectContext: moc)
        
        fetchRequest.entity = entityDescription
        
        do {
            let fetchedmsgsCD = try moc.executeFetchRequest(fetchRequest) as! [Message]
            let Usersendername = NSUserData.stringForKey("recordID")!//user user unique id
            
            var i = 0
            while  i <= (fetchedmsgsCD.count - 1){//loops through all of coredata store
                
                if typeOfCrumbLoading == true{//load your CrumbMessages
                    if fetchedmsgsCD[i].senderuuid! == Usersendername {//compares sendername of user's to msgs and returns user's msgs
                        let fmtext = fetchedmsgsCD[i].text! as String
                        let fmsenderName = fetchedmsgsCD[i].senderName! as String
                        let fmlocation = fetchedmsgsCD[i].cdlocation() as CLLocation
                        let fmtimedropped = fetchedmsgsCD[i].timeDropped! as NSDate
                        let fmtimelimit = fetchedmsgsCD[i].timeLimit as! Int
                        let fmsenderuuid = fetchedmsgsCD[i].senderuuid! as String
                        let fmvotes = fetchedmsgsCD[i].votevalue as! Int
                        let fmaddressStr = fetchedmsgsCD[i].addressStr as String!
                        
                        let fmCrumbMessageYours = CrumbMessage(text: fmtext, senderName: fmsenderName, location: fmlocation, timeDropped: fmtimedropped, timeLimit: fmtimelimit, senderuuid: fmsenderuuid, votes: fmvotes)
                        
                        fmCrumbMessageYours?.uRecordID = fetchedmsgsCD[i].recorduuid! as String
                        fmCrumbMessageYours?.addressStr = fmaddressStr
                        crumbmessagestoload += [fmCrumbMessageYours!]
                        
                    }
                }
                else if typeOfCrumbLoading == false{//load others CrumbMessages
                    if fetchedmsgsCD[i].senderuuid! != Usersendername{//compares sendername of users and returns others msgs
                        let fmtext = fetchedmsgsCD[i].text! as String
                        let fmsenderName = fetchedmsgsCD[i].senderName! as String
                        let fmlocation = fetchedmsgsCD[i].cdlocation() as CLLocation
                        let fmtimedropped = fetchedmsgsCD[i].timeDropped! as NSDate
                        let fmtimelimit = fetchedmsgsCD[i].timeLimit as! Int
                        let fmsenderuuid = fetchedmsgsCD[i].senderuuid! as String
                        let fmvote = fetchedmsgsCD[i].votevalue! as Int
                        let fmrecorduuid = fetchedmsgsCD[i].recorduuid! as String
                        let fmhasVoted = fetchedmsgsCD[i].hasVoted as! Int
                        //let fmviewedOther = fetchedmsgsCD[i].viewedOther as! Int
                        let fmaddressStr = fetchedmsgsCD[i].addressStr as String!
                        
                        let fmCrumbMessageOther = CrumbMessage(text: fmtext, senderName: fmsenderName, location: fmlocation, timeDropped: fmtimedropped, timeLimit: fmtimelimit, senderuuid: fmsenderuuid, votes: fmvote)
                        fmCrumbMessageOther?.uRecordID = fmrecorduuid
                        fmCrumbMessageOther?.hasVoted = fmhasVoted
                        //fmCrumbMessageOther?.viewedOther = fmviewedOther
                        fmCrumbMessageOther?.addressStr = fmaddressStr
                        
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
    
    
    
    //MARK: UPDATE
    
    
    //used in appdelegate in application did become active /IS UNTESTED/
    func updateTableViewVoteValues(){
        
        //grab all crumbs within cd that are alive
        // ******************************************
        var RecordIDsToTest = [String]()//takes ids of stored alive crumbs
        
        let fetchRequest = NSFetchRequest()
        let entityDescription = NSEntityDescription.entityForName("Message", inManagedObjectContext: moc)
        
        fetchRequest.entity = entityDescription
        
        do {
            let fetchedmsgsCD = try moc.executeFetchRequest(fetchRequest) as! [Message]
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
        
        let container = CKContainer.defaultContainer()
        let publicData = container.publicCloudDatabase
        
        for id in RecordIDsToTest{
            let ckidToTest = CKRecordID(recordName: id)//the message record id to fetch from cloudkit
            
            publicData.fetchRecordWithID(ckidToTest, completionHandler: {record, error in
                if error == nil{
                    let newvalue = record!.objectForKey("votes") as! Int
                    
                    //update cd with new vote values
                    // *******************************************/
                    self.updateCdVote(id, voteValue: newvalue)
                }else{
                    print(error)
                }
            })
        }
        
        
       
    }
    
    //used above, takes id and new vote value and updates the alive message. I think
    func updateCdVote(cdrecorduuid: String, voteValue: Int){
        let predicate = NSPredicate(format: "recorduuid == %@", cdrecorduuid)
        let fetchRequest = NSFetchRequest(entityName: "Message")
        fetchRequest.predicate = predicate
        
        do {// change it, it not work y?
            let fetchedMsgs = try AppDelegate().managedObjectContext.executeFetchRequest(fetchRequest) as! [Message]

            fetchedMsgs.first?.setValue(voteValue, forKey: "votevalue")
            
            do {// save it!
                try AppDelegate().managedObjectContext.save()
                print("did save")
                
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
    }
    
    
    
    //MARK: SAVE
    func saveToCoreData(crumbmessage: CrumbMessage){
        //create Message: NSManagedObject
        
        let messageMO = NSEntityDescription.insertNewObjectForEntityForName("Message", inManagedObjectContext: moc) as! BreadCrumbs.Message
        
        messageMO.setValue(crumbmessage.text, forKey: "text")
        messageMO.setValue(crumbmessage.senderName, forKey: "senderName")
        messageMO.setValue(crumbmessage.timeDropped, forKey: "timeDropped")
        messageMO.setValue(crumbmessage.timeLimit, forKey: "timeLimit")
        messageMO.initFromLocation(crumbmessage.location)
        messageMO.setValue(crumbmessage.senderuuid, forKey: "senderuuid")
        messageMO.setValue(crumbmessage.votes, forKey: "votevalue")
        messageMO.setValue(crumbmessage.uRecordID, forKey: "recorduuid")
        //messageMO.setValue(0, forKey: "viewedOther")
        messageMO.setValue(0, forKey: "hasVoted")
        messageMO.setValue(crumbmessage.addressStr, forKey: "addressStr")
        
        do {
            try messageMO.managedObjectContext?.save()
            print("a message has been loaded and stored into coredata")
            
            if /*usernotification value == true*/ true{
                //notify user a new msg is here with notification
                
            }
            
            //print("updated and stored more butts")
        } catch {
            print(error)
        }
    }
    
    
    //MARK: DELETE
    func cloudKitDeleteCrumb(currentRecordID: CKRecordID){//should only be used by timelimit checkers/load and store
        
        let container = CKContainer.defaultContainer()
        let publicData = container.publicCloudDatabase
        
        publicData.deleteRecordWithID(currentRecordID, completionHandler: { (record, error) in
            if error == nil{
                print("record is deleted from cloudkit")
            }else{
                print(error)
                //alert user delete failed
            }
        })
        
        //save?
    }
    
    func coreDataDeleteCrumb(cdrecorduuid: String){
        let cdPredicate = NSPredicate(format: "recorduuid == %@", cdrecorduuid)

        let fetchRequest = NSFetchRequest(entityName: "Message")
        fetchRequest.predicate = cdPredicate
        
        do {
            let fetchedEntities = try moc.executeFetchRequest(fetchRequest) as! [Message]
            if let entityToDelete = fetchedEntities.first {
                moc.deleteObject(entityToDelete)
                print("record is deleted from coredata")
            }
        } catch {
            // Do something in response to error condition
            print("something went wrong")
            print(error)
        }
        do {
            try moc.save()
        } catch {
            print(error)
            // Do something in response to error condition
        }
    }
    
    
    //MARK: Notification
    
    func pingNotifications(){//used in appdelegate/load and store, only by others crumbs
        notify()
        print("ping notif: new Breadcrumb!")//ping notif
        
    }
    
    
    //Notification function for load and store
    
    func notify() {
        guard let settings = UIApplication.sharedApplication().currentUserNotificationSettings() else { return }
        
        if settings.types == .None {
            let ac = UIAlertController(title: "Can't schedule", message: "Either we don't have permission to schedule notifications, or we haven't asked yet.", preferredStyle: .Alert)
            ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            return
        }
        
        let notification = UILocalNotification()
        notification.fireDate = NSDate(timeIntervalSinceNow: 5)
        notification.alertBody = "SaUcy breadcrumbs are near you! come check'em out!"
        notification.alertAction = "just kidding!"
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.userInfo = ["CustomField1": "w00t"]
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }

    
    //Coredata Needs
    
    
    lazy var moc: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "uk.co.plymouthsoftware.core_data" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("MessageDataModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("BreadCrumbs.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    //Core Data Saving support
    func saveContext () {
        if moc.hasChanges {
            do {
                try moc.save()
            } catch {
                
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
}
