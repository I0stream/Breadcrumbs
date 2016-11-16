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
                                        
                    let loadedMessage = CrumbMessage(text: dbtext, senderName: dbsenderName, location: dblocation, timeDropped: dbtimedropped, timeLimit: dbtimelimit, senderuuid: dbsenderuuid, votes: dbvotes)
                    
                    loadedMessage!.uRecordID = uniqueRecordID
                    
                    let testID = loadedMessage?.senderuuid != self.NSUserData.string(forKey: "recordID")!
                    
                    print(loadedMessage?.senderName as Any)
                    print(loadedMessage?.location.description as Any)
                    print(loadedMessage!.calculate())
                    
                    if (loadedMessage!.calculate() > 0) && testID{
                        
                        //TESTS IF LOADED MSG IS IN COREDATA IF NOT THEN STORES IT BRAH
                        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Message")
                        let cdPredicate = NSPredicate(format: "recorduuid == %@", loadedMessage!.uRecordID!)
                        fetchRequest.predicate = cdPredicate
                        
                        do {
                            if let fetchResults = try self.moc.fetch(fetchRequest) as? [Message]{
                                if fetchResults.isEmpty{//keep reading tuts man your having mucho trouble-o
                                    //loadedMessage!.convertCoordinatesToAddress((loadedMessage!.location), completion: { (answer) in
                                        
                                        //loadedMessage!.addressStr = answer!
                                        
                                        self.saveToCoreData(loadedMessage!)
                                        if UIApplication.shared.applicationState != UIApplicationState.active{
                                            self.notify()//if this is how we will do it, we must have a seen and unseen marker
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
                    }
                    else if loadedMessage!.calculate() <= 0//if message is past due delete the ckufer
                    {
                        //delete, I think
                        print("delete crumb")
                        print(loadedMessage!)
                        
                        let yum = CKRecordID(recordName: (loadedMessage?.uRecordID)!)
                        self.cloudKitDeleteCrumb(yum)
                        
                        //print("Finished request delete \(cmsg)")
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
        let entityDescription = NSEntityDescription.entity(forEntityName: "Message", in: moc)
        
        fetchRequest.entity = entityDescription
        
        do {
            let fetchedmsgsCD = try moc.fetch(fetchRequest) as! [Message]
            
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
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        let entityDescription = NSEntityDescription.entity(forEntityName: "Message", in: moc)
        
        fetchRequest.entity = entityDescription
        
        do {
            let fetchedmsgsCD = try moc.fetch(fetchRequest) as! [Message]
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
                        //let fmaddressStr = fetchedmsgsCD[i].addressStr as String!
                        
                        let fmCrumbMessageOther = CrumbMessage(text: fmtext, senderName: fmsenderName, location: fmlocation, timeDropped: fmtimedropped, timeLimit: fmtimelimit, senderuuid: fmsenderuuid, votes: fmvote)
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
    
    //MARK: UPDATE
    
    
    //used in appdelegate in application did become active /IS UNTESTED/
    func updateTableViewVoteValues(){//checks for all msgs, need to do it only for alive msgs
        
        //grab all crumbs within cd that are alive
        // ******************************************
        var RecordIDsToTest = [String]()//takes ids of stored alive crumbs
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        let entityDescription = NSEntityDescription.entity(forEntityName: "Message", in: moc)
        
        fetchRequest.entity = entityDescription
        
        do {
            let fetchedmsgsCD = try moc.fetch(fetchRequest) as! [Message]
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
                    self.updateCdVote(id, voteValue: newvalue)
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
            let fetchedMsgs = try AppDelegate().managedObjectContext.fetch(fetchRequest) as! [Message]

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
    func saveToCoreData(_ crumbmessage: CrumbMessage){
        //create Message: NSManagedObject
        
        let messageMO = NSEntityDescription.insertNewObject(forEntityName: "Message", into: moc) as! BreadCrumbs.Message
        
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
                
            }
            
            //print("updated and stored more butts")
        } catch {
            print(error)
        }
    }
    
    
    //MARK: DELETE
    @objc func cloudKitDeleteCrumb(_ currentRecordID: CKRecordID){//should only be used by timelimit checkers/load and store
        
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
    
    func coreDataDeleteCrumb(_ cdrecorduuid: String){
        let cdPredicate = NSPredicate(format: "recorduuid == %@", cdrecorduuid)

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Message")
        fetchRequest.predicate = cdPredicate
        
        do {
            let fetchedEntities = try moc.fetch(fetchRequest) as! [Message]
            if let entityToDelete = fetchedEntities.first {
                moc.delete(entityToDelete)
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
    
    //Notification function for load and store
    
    func notify() {//used in load and store
        guard let settings = UIApplication.shared.currentUserNotificationSettings else { return }
        
        if settings.types == UIUserNotificationType() {
            let ac = UIAlertController(title: "Can't schedule", message: "Either we don't have permission to schedule notifications, or we haven't asked yet.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            return
        }
        
        let notification = UILocalNotification()
        notification.fireDate = Date(timeIntervalSinceNow: 5)
        notification.alertBody = "New Breadcrumbs! come check'em out!"
        notification.alertAction = "Confirm"
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.userInfo = ["CustomField1": "w00t"]
        UIApplication.shared.scheduleLocalNotification(notification)
        
        print("ping notif: new Breadcrumb!")//ping notif
        NotificationCenter.default.post(name: Notification.Name(rawValue: "loadOthers"), object: nil)//loads new msgs from cd
    }

    
    //Coredata Needs
    
    
    lazy var moc: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "uk.co.plymouthsoftware.core_data" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "MessageDataModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("BreadCrumbs.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
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
