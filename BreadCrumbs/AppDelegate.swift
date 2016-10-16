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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var locationManager = CLLocationManager()
    var seenError : Bool = false
    var locationFixAchieved : Bool = false
    var locationStatus : NSString = "Not Started"
    let NSUserData = NSUserDefaults.standardUserDefaults()
    let helperfunctions = Helper()
    
    
    var timer1 = NSTimer()
    var timer2 = NSTimer()
    
    var backgroundLocationTask: UIBackgroundTaskIdentifier?
    
    var myGroup = dispatch_group_create()

    //how bout i test this fucker by putting a bullet in it
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        //self.NSUserData.setValue(0, forKey: "crumbCount")

        /*IF internet access or cell phone service or locationservices are nil
         let the user know and dont crash app
         */
        //test if user is signed in. if he is, go to pgmanagerVC; if not, go to signInVC
        
        /*if CFloat(UIDevice.currentDevice().systemVersion) >= 7 {
            application.statusBarStyle = .LightContent
            self.window!.clipsToBounds = true
            self.window!.frame = CGRectMake(0, 20, self.window!.frame.size.width, self.window!.frame.size.height - 20)
        }*/
        
        self.NSUserData.setValue(0, forKey: "counterLoc")
     
        if isICloudContainerAvailable() && NSUserData.stringForKey("userName") != nil{
            self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            let initialViewController = storyboard.instantiateViewControllerWithIdentifier("pgManager") as! PageManagerViewController
            //let initialViewController = storyboard.instantiateViewControllerWithIdentifier("tabBarTest") as! UITabBarController
            
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
            
            //gets and sets userrecordID
            if NSUserData.stringForKey("recordID") == nil/*|| user != signedIn*/{
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
            
            //***********************************************************************************************************************//

            initLocationManager()
            
            application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil))            
            
            //***********************************************************************************************************************//

            AppDelegate().NSUserData.setValue(0, forKey: "limitArea")
            
            self.timer1 = NSTimer.scheduledTimerWithTimeInterval(60.0, target: self, selector: #selector(AppDelegate.loadAndStoreiCloudMsgsBasedOnLoc), userInfo: nil, repeats: true)//checks icloud every 60 sec for a msg
            
        }
        
        else {
            self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            let initialViewController = storyboard.instantiateViewControllerWithIdentifier("SignIn")
            
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
        }
        
        return true
    }
    
    //MARK: notifications
    
    
    func testssss() -> Void{
        helperfunctions.pingNotifications()
    }
    
    //MARK: Location Stuff
    //***********************************************************************************************************************//
    
    
    func initLocationManager() {
        seenError = false
        locationFixAchieved = false
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
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
            
            locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers

            print("load and store has run")
        }
    }
    
    //***********************************************************************************************************************//


    //mine inits
    func isICloudContainerAvailable()->Bool {
        if NSFileManager.defaultManager().ubiquityIdentityToken != nil {
            return true
        }
        else {
            return false
        }
    }
    
    //MARK: Further cloudkit functions
    //***********************************************************************************************************************//
    func iCloudUserIDAsync(complete: (instance: CKRecordID?, error: NSError?) -> ()) {
        let container = CKContainer.defaultContainer()
        container.fetchUserRecordIDWithCompletionHandler() {
            recordID, error in
            if error != nil {
                print(error!.localizedDescription)
                complete(instance: nil, error: error)
            } else {
                complete(instance: recordID, error: nil)
            }
        }
    }
    
    func getUserInfo(){
        let container = CKContainer.defaultContainer()
        let publicData = container.publicCloudDatabase
        let CKuserID: CKRecordID = CKRecordID(recordName: NSUserData.stringForKey("recordID")!)
        
        let query = CKQuery(recordType: "UserInfo", predicate: NSPredicate(format: "%K == %@", "creatorUserRecordID" ,CKReference(recordID: CKuserID, action: CKReferenceAction.None)))
        
        publicData.performQuery(query, inZoneWithID: nil) {
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
                print(error)
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
        var cCount = NSUserData.integerForKey("crumbCount")
        
        let Lastdate:NSDate? = NSUserData.objectForKey("SinceLastCheck") as? NSDate
        
        if cCount < 5 && Lastdate?.description != nil{//extra hour is sneeking its way in here soumehow
            
            var oldExcess = NSUserData.objectForKey("excesstime") as? Double//excess 'seconds' from last check
            
            if oldExcess == nil {//if blank give it zero
                oldExcess = 0.0
            }
            
            let timeElapsedh = Int((-Lastdate!.timeIntervalSinceNow + oldExcess!) / 3600)//converts nsdate to time elapsed in hours
            let excess = round((-Lastdate!.timeIntervalSinceNow + oldExcess!) % 3600)
            
            print("hours elapsed:\(timeElapsedh) extra seconds stored:\(round(oldExcess!)) s")
            
            if timeElapsedh + cCount <= 5 && timeElapsedh >= 1 {
                cCount = cCount + timeElapsedh
                self.NSUserData.setValue(cCount, forKey: "crumbCount")
            }else if timeElapsedh > 5 {
                cCount = 5
                NSUserData.setValue(cCount, forKey: "crumbCount")
            }
            
            self.NSUserData.setValue(excess, forKey: "excesstime")//unused seconds from this check
            
            self.NSUserData.setValue(NSDate(), forKey: "SinceLastCheck")
        }
     
     }
    
    // Location Manager Delegate stuff
    //***********************************************************************************************************************//

    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        locationManager.stopUpdatingLocation()
        print(error)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    }
    
    func locationManager(manager: CLLocationManager,
                         didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        var shouldIAllow = false
        
        switch status {
        case CLAuthorizationStatus.Restricted:
            locationStatus = "Restricted Access to location"
        case CLAuthorizationStatus.Denied:
            locationStatus = "User denied access to location"
        case CLAuthorizationStatus.NotDetermined:
            locationStatus = "Status not determined"
        default:
            locationStatus = "Allowed to location Access"
            shouldIAllow = true
        }
        NSNotificationCenter.defaultCenter().postNotificationName("LabelHasbeenUpdated", object: nil)
        if (shouldIAllow == true) {
            NSLog("Location to Allowed")
            // Start location services
            locationManager.startUpdatingLocation()
        } else {
            NSLog("Denied access: \(locationStatus)")
        }
    }
    
    
    // MARK: - Core Data stack, redundant?
    //***********************************************************************************************************************//

        lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("MessageDataModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
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
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {

                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }

    //MARK: misc stack
    //***********************************************************************************************************************//

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        self.NSUserData.setValue(0, forKey: "counterLoc")
        AddCrumbCount()
        self.saveContext()
        
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        NSNotificationCenter.defaultCenter().postNotificationName("loadYours", object: nil)//reloads crmessages from cd
        NSNotificationCenter.defaultCenter().postNotificationName("loadOthers", object: nil)//loads new msgs from cd
        AddCrumbCount()
        helperfunctions.updateTableViewVoteValues()
        

        //When app is reopened check cloudkit for updated vote values for crumbs that are still alive
    }
    
    func applicationWillTerminate(application: UIApplication) {//when app terminates terminate timers and look for large loc changes
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:
        
        self.saveContext()
    }
    
}
