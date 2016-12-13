//
//  AppDelegate.swift
//  BreadCrumb
//
//  Created by Daniel Schliesing on 4/9/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import CoreLocation
import UIKit
import CoreData
import CloudKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate, UNUserNotificationCenterDelegate{

    var window: UIWindow?
    var locationManager = CLLocationManager()
    var seenError : Bool = false
    var locationFixAchieved : Bool = false
    var locationStatus : NSString = "Not Started"
    let NSUserData = UserDefaults.standard
    let helperfunctions = Helper()
    
    weak var timer1 = Timer()
    
    var backgroundLocationTask: UIBackgroundTaskIdentifier?
    
    //var myGroup = dispatch_group_create()

    //how bout i test this fucker by putting a bullet in it
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        self.NSUserData.setValue(0, forKey: "counterLoc")
        
        if isICloudContainerAvailable() && NSUserData.string(forKey: "userName") != nil && NSUserData.string(forKey: "recordID") != nil{
            self.window = UIWindow(frame: UIScreen.main.bounds)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            
            let initialViewController = storyboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
            
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
            
            initLocationManager()
            
            
            //***********************************************************************************************************************//
            
            AppDelegate().NSUserData.setValue(0, forKey: "limitArea")
            
            self.timer1 = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(AppDelegate.loadAndStoreiCloudMsgsBasedOnLoc), userInfo: nil, repeats: true)//checks icloud every 60 sec for a msg
            
            saveContext()
            //***********************************************************************************************************************//

            
        } else {
            self.window = UIWindow(frame: UIScreen.main.bounds)
            
            
            //gets and sets userrecordID
            if NSUserData.string(forKey: "recordID") == nil/*|| user != signedIn*/{
                iCloudUserIDAsync() {
                    recordID, error in
                    if let userID = recordID?.recordName {
                        print("received iCloudID \(userID)")
                        self.NSUserData.setValue(userID, forKey: "recordID")
                        self.getUserInfo()
                        //checks crumbcount and populates it, populates premium with most recent value
                    } else {
                        print("Fetched iCloudID was nil")
                    }
                }
            }
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            let initialViewController = storyboard.instantiateViewController(withIdentifier: "pgManager") as! PageManagerViewController
            //let initialViewController = storyboard.instantiateViewControllerWithIdentifier("IntroShill")
            
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
        }
        
        return true
    }
    
    func saveToCoreData(){
        //create Message: NSManagedObject
        if #available(iOS 10.0, *) {
            
            let moc = persistentContainer.viewContext
            
            let entity = NSEntityDescription.entity(forEntityName: "Message", in: moc)
            let message = Message(entity: entity!, insertInto: moc)
            
            /*message.setValue(crumbmessage.text, forKeyPath: "text")
             message.setValue(crumbmessage.senderName, forKeyPath: "senderName")
             message.setValue(crumbmessage.timeDropped, forKeyPath: "timeDropped")
             message.setValue(crumbmessage.timeLimit as NSNumber?, forKey: "timeLimit")
             message.
             message.setValue(crumbmessage.senderuuid, forKeyPath: "senderuuid")
             message.setValue(crumbmessage.votes as NSNumber?, forKeyPath: "votevalue")
             message.setValue(crumbmessage.uRecordID, forKeyPath: "recorduuid")*/
            let crumbmessage = CrumbMessage(text: "hello", senderName: "test", location: locationManager.location!, timeDropped: Date(), timeLimit: 48, senderuuid: "adsfasfzcxvkhlweqr", votes: 12)
            
            message.text = crumbmessage?.text
            message.senderName = crumbmessage?.senderName
            message.timeDropped = crumbmessage?.timeDropped
            message.timeLimit = crumbmessage?.timeLimit as NSNumber?
            message.initFromLocation((crumbmessage?.location)!)
            message.senderuuid = crumbmessage?.senderuuid
            message.votevalue = crumbmessage?.votes as NSNumber?
            message.recorduuid = crumbmessage?.uRecordID
            do {
                try message.managedObjectContext?.save()
                //print("saved to coredata")
            } catch {
                print(error)
                print("cd error in write crumbs")
                
            }
        }
    }
    //MARK: Location Stuff
    //***********************************************************************************************************************//
    
    
    func initLocationManager() {
        DispatchQueue.main.async(execute: { () -> Void in

            self.seenError = false
            self.locationFixAchieved = false
            self.locationManager = CLLocationManager()
            self.locationManager.delegate = self
            self.locationManager.requestAlwaysAuthorization()
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.allowsBackgroundLocationUpdates = true
        })
    }
    

    
    //MARK: save icloud msgs to coreData
    //***********************************************************************************************************************//
    //constant checking for new msgs
    
    func loadAndStoreiCloudMsgsBasedOnLoc(){// load icloud msgs; need to check if msg is already loaded & store loaded msgs to persist between views and app instances
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //my error handling is top notch
        let currentUserLoc = locationManager.location // if location changes bad things happen D:
        if currentUserLoc != nil {
            let radius = 20 //for now we use this but hopefully in the future we can multiply this by the votevalue metes
            
            let predicate: NSPredicate = NSPredicate(format: "distanceToLocation:fromLocation:(location, %@)< %f", currentUserLoc!, radius)
            
            let query = CKQuery(recordType: "CrumbMessage", predicate: predicate)
            
            helperfunctions.loadIcloudMessageToCoreData(query)
            print("load and store has run")
            locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers

        }
    }

    
    //***********************************************************************************************************************//


    //mine inits
    func isICloudContainerAvailable()->Bool {
        if FileManager.default.ubiquityIdentityToken != nil {
            return true
        }
        else {
            return false
        }
    }
    
    //MARK: Further cloudkit functions
    //***********************************************************************************************************************//
    func iCloudUserIDAsync(_ complete: @escaping (_ instance: CKRecordID?, _ error: NSError?) -> ()) {
        let container = CKContainer.default()
        container.fetchUserRecordID() {
            recordID, error in
            if error != nil {
                print(error!.localizedDescription)
                complete(nil, error as NSError?)
            } else {
                complete(recordID, nil)
            }
        }
    }
    
    func getUserInfo(){
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        let CKuserID: CKRecordID = CKRecordID(recordName: NSUserData.string(forKey: "recordID")!)
        
        let query = CKQuery(recordType: "UserInfo", predicate: NSPredicate(format: "%K == %@", "creatorUserRecordID" ,CKReference(recordID: CKuserID, action: CKReferenceAction.none)))
        
        publicData.perform(query, inZoneWith: nil) {
            results, error in
            if error == nil{
                for userinfo in results! {//need to have this update if user has already signed in before
                    let crumbCountCD = userinfo["crumbCount"] as! Int
                    let userName = userinfo["userName"] as! String
                    let premiumStatus = userinfo["premiumStatus"] as! Bool
                    let recordName = userinfo.recordID.recordName
                    
                    self.NSUserData.setValue(userName, forKey: "userName")
                    self.NSUserData.setValue(crumbCountCD, forKey: "crumbCount")
                    self.NSUserData.setValue(premiumStatus, forKey: "premiumStatus")
                    self.NSUserData.setValue(recordName, forKey: "recordName")
                }
            }else{
                print(error!)
            }
        }
        
    }
    
    //crumb count checker adder
    //
    //the purpose of this function is to aggregate time and test if that time is enough to get a crumb
    //(crumbs every hour with a limit of 5)
    //
    //take the date of last check, compare it to now. take that interval and seperate it into hours and minutes
    //for every hour add a crumb
    //extra seconds get stored in excesstime
    //reset date of last check to now
    //***********************************************************************************************************************//
    func AddCrumbCount(){//for both nsuserdefaults and cloudkit
        var cCount = NSUserData.integer(forKey: "crumbCount")
        
        let Lastdate:Date? = NSUserData.object(forKey: "SinceLastCheck") as? Date
        
        if cCount < 7 && Lastdate?.description != nil{//extra hour is sneeking its way in here soumehow
            
            var oldExcess = NSUserData.object(forKey: "excesstime") as? Double//excess 'seconds' from last check
            
            if oldExcess == nil {//if blank give it zero
                oldExcess = 0.0
            }
            
            let timeElapsedh = Int((-Lastdate!.timeIntervalSinceNow + oldExcess!) / 3600)//converts nsdate to time elapsed in hours
            let excess = round((-Lastdate!.timeIntervalSinceNow + oldExcess!).truncatingRemainder(dividingBy: 3600))
            
            //print("hours elapsed:\(timeElapsedh) extra seconds stored:\(round(oldExcess!)) s")
            
            if timeElapsedh + cCount <= 7 && timeElapsedh >= 1 {
                cCount = cCount + timeElapsedh
                self.NSUserData.setValue(cCount, forKey: "crumbCount")
            }else if timeElapsedh > 7 {
                cCount = 7
                NSUserData.setValue(cCount, forKey: "crumbCount")
            }
            
            self.NSUserData.setValue(excess, forKey: "excesstime")//unused seconds from this check
            
            self.NSUserData.setValue(Date(), forKey: "SinceLastCheck")
            
        }
     
     }
    
    // Location Manager Delegate stuff
    //***********************************************************************************************************************//

    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        var shouldIAllow = false
        
        switch status {
        case CLAuthorizationStatus.restricted:
            locationStatus = "Restricted Access to location"
        case CLAuthorizationStatus.denied:
            locationStatus = "User denied access to location"
        case CLAuthorizationStatus.notDetermined:
            locationStatus = "Status not determined"
        default:
            locationStatus = "Allowed to location Access"
            shouldIAllow = true
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "LabelHasbeenUpdated"), object: nil)
        if (shouldIAllow == true) {
            NSLog("Location to Allowed")
            // Start location services
            locationManager.startUpdatingLocation()
        } else {
            NSLog("Denied access: \(locationStatus)")
        }
    }
    
    
    // MARK: - Core Data stack?
    //***********************************************************************************************************************//
    @available(iOS 10.0, *)
    lazy var persistentContainer: NSPersistentContainer = {
        //let modelURL = Bundle.main.url(forResource: "MessageDataModel", withExtension: "momd")!
        //var managedModel = NSManagedObjectModel(contentsOf: modelURL)
        
        let container = NSPersistentContainer(name: "MessageDataModel")
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()
    
    //for older versions probably
    @available(iOS 9.3, *)
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    @available(iOS 9.3, *)
    lazy var applicationDocumentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    @available(iOS 9.3, *)
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: "MessageDataModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    @available(iOS 9.3, *)
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
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
    func getContext() -> NSManagedObjectContext{
        if #available(iOS 10.0, *) {
            let context = self.persistentContainer.viewContext
            return context
            
        } else {
            let context = self.managedObjectContext
            return context
        }
    }
    
    //Core Data Saving support
    func saveContext () {
        if getContext().hasChanges {
            do {
                try getContext().save()
            } catch {

                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }

    //MARK: misc stack
    //***********************************************************************************************************************//

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        self.NSUserData.setValue(0, forKey: "counterLoc")
        AddCrumbCount()
        self.saveContext()
        
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        if isICloudContainerAvailable() && NSUserData.string(forKey: "userName") != nil{
            loadAndStoreiCloudMsgsBasedOnLoc()//not this
            //UPDATE VOTES HERE
            
            helperfunctions.updateTableViewVoteValues()//updates all votes
            
            //helperfunctions.updateTableViewcomments()//this fucks my shit up so hard
            
            //should use delegation or something
            NotificationCenter.default.post(name: Notification.Name(rawValue: "load"), object: nil)//reloads crmessages from cd everywhere
            AddCrumbCount()
            /*if !checkLocation(){
                
            }*/
            
        }else if isICloudContainerAvailable() && NSUserData.string(forKey: "userName") == nil{
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ReloadSignIn"), object: nil)
            
            self.window = UIWindow(frame: UIScreen.main.bounds)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            let initialViewController = storyboard.instantiateViewController(withIdentifier: "SignIn")
            
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
        }

        //When app is reopened check cloudkit for updated vote values for crumbs that are still alive
    }
    
    func applicationWillTerminate(_ application: UIApplication) {//when app terminates terminate timers and look for large loc changes
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:
        
        self.saveContext()
    }
    func checkLocation() -> Bool{
        if locationManager.location != nil{
            return true
        } else{
            return false
        }
    }
    //MARK: Notification
    
    //Notification function for load and store
    
    func notify() {//used in load and store
        let requestIdentifier = "SampleRequest" //identifier is to cancel the notification request

        if #available(iOS 10.0, *) {
            
            let content = UNMutableNotificationContent()
            content.title = "Intro to Notifications"
            content.subtitle = "Lets code,Talk is cheap"
            content.body = "New Breadcrumbs! come check'em out!"
            content.sound = UNNotificationSound.default()
            
            // Deliver the notification in five seconds.
            let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 5.0, repeats: false)
            let request = UNNotificationRequest(identifier:requestIdentifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().delegate = self
            UNUserNotificationCenter.current().add(request){(error) in
                
                if (error != nil){
                    
                    print(error?.localizedDescription ?? "error in notify")
                }
            }
        } else {
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
    }
}
