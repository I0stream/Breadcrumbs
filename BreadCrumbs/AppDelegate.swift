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
    
    let NSUserData = UserDefaults.standard//for storing states and numbers
    
    var locationManager = CLLocationManager()//location stuff
    var seenError : Bool = false
    var locationFixAchieved : Bool = false
    var locationStatus : NSString = "Not Started"
    var bestEffortAtLocation: CLLocation!//see didupdatelocation or whatever
    var bestCurrent: CLLocation?
    
    weak var timerRepeatLoadAndStore = Timer()//for keeping track of load and store
    
    let helperfunctions = Helper()//contains various cd and ck functions
    lazy var CDStack = CoreDataStack()//cd req functions
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        //helperfunctions.cloudkitSub()

        UNUserNotificationCenter.current().delegate = self
        
        /*UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if granted {
                let clear = UNNotificationAction(identifier: "testing", title: "test", options: [])
                let category : UNNotificationCategory = UNNotificationCategory.init(identifier: "CALLINNOTIFICATION", actions: [clear], intentIdentifiers: [], options: [])
                
                let center = UNUserNotificationCenter.current()
                center.setNotificationCategories([category])

            }
        }
        
        let clear = UNNotificationAction(identifier: "testing", title: "test", options: [])
        let category : UNNotificationCategory = UNNotificationCategory.init(identifier: "CALLINNOTIFICATION", actions: [clear], intentIdentifiers: [], options: [])
        
        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories([category])
        */
        // Register with APNs
        application.registerForRemoteNotifications()
        
        //accountStatus()// is icloud drive available?
        accountStatus()

        if NSUserData.string(forKey: "recordID") != nil{
            getUserInfo()

        }
        application.applicationIconBadgeNumber = 0
        
        //is icloud available? is icloud drive available? does he have a username? does user have a stored user id?
        //if so go to app
        // NSUserData.string(forKey: "didAgreeToPolAndEULA") == "Agree"

        if TestIfUserSignedIn(){//Signed in
            //let launchinfo = launchOptions?.values
            //print(launchinfo)
            
            /*let dictionary = userInfo
            let recordid = dictionary["RecordUuid"] as? String
            let userid = dictionary["UserId"] as? String
            
            
            if response.actionIdentifier == UNNotificationDefaultActionIdentifier && recordid != nil{
                notifTakeToCrumb(userid: userid!, recordid: recordid!)
            }*/
            
            
            self.window = UIWindow(frame: UIScreen.main.bounds)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            let initialViewController = storyboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
            
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
            
            UIApplication.shared.applicationIconBadgeNumber = 0
            
            initLocationManager()
            
            AddCrumbCount()//checks to see and if so adds more crumbs to users
            
            timerForLoadAndStore()//starts checking for messages with load and store if needed  
            
            AppDelegate().NSUserData.setValue(0, forKey: "limitArea")
            
            if NSUserData.object(forKey: "badgeOther") == nil {
                NSUserData.setValue(0, forKey: "badgeOther")
                print("was empty")
            }
            
            CDStack.saveContext()
            
        } else if !isBanned(){
            self.window = UIWindow(frame: UIScreen.main.bounds)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            
            let initialViewController = storyboard.instantiateViewController(withIdentifier: "Banned")
            
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
        }else {//if not go to sign in
            
            //gets and sets userrecordID
            if NSUserData.string(forKey: "recordID") == nil{//keychain
                iCloudUserIDAsync() {
                    recordID, error in
                    if let userID = recordID?.recordName {
                        print("received iCloudID \(userID)")
                        self.NSUserData.setValue(userID, forKey: "recordID")//switch to keychain?
                        self.getUserInfo()
                        self.NSUserData.setValue(Date(), forKey: "SinceLastCheck")
                        //checks crumbcount and populates it, populates premium with most recent value
                    } else {
                        print("Fetched iCloudID was nil")
                    }
                }
            }
            
            
            self.window = UIWindow(frame: UIScreen.main.bounds)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            let initialViewController = storyboard.instantiateViewController(withIdentifier: "Welcome") as! WelcomeViewController
            
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
        }
        
        return true
    }
    
    
    func TestIfUserSignedIn()-> Bool{
        if isICloudContainerAvailable() && NSUserData.bool(forKey: "ckAccountStatus") && NSUserData.string(forKey: "userName") != nil && NSUserData.string(forKey: "recordID") != nil && NSUserData.string(forKey: "didAgreeToPolAndEULA") == "Agree" && isBanned() {
           return true
        }else{
            return false
        }
    }
    
    func isBanned() -> Bool{
        
        let isbanValue = self.NSUserData.string(forKey: "banned") == "banned"

        
        let notbanned = self.NSUserData.string(forKey: "banned") != "banned"

        if notbanned{
            return true//not banned
        }else if isbanValue{
            return false
        }else{
            return false
        }
    }
    
    
    
    func accountStatus(){
        let container = CKContainer.default()
        container.accountStatus { (status, error) in
            switch status.rawValue {
            case 1 ://available
                self.NSUserData.setValue(true, forKey: "ckAccountStatus")
            default:
                self.NSUserData.setValue(false, forKey: "ckAccountStatus")
            }
        }
    }
    
    func getUserInfo(){
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        let CKuserID: CKRecordID = CKRecordID(recordName: NSUserData.string(forKey: "recordID")!)//keychain
        
        let query = CKQuery(recordType: "UserInfo", predicate: NSPredicate(format: "%K == %@", "creatorUserRecordID" ,CKReference(recordID: CKuserID, action: CKReferenceAction.none)))
        
        publicData.perform(query, inZoneWith: nil) {
            results, error in
            if error == nil{
                for userinfo in results! {//need to have this update if user has already signed in before
                    let userName = userinfo["userName"] as! String
                    let premiumStatus = userinfo["premiumStatus"] as! Bool
                    let recordName = userinfo.recordID.recordName
                    let banned = userinfo["Banned"] as! String
                    let agree = userinfo["Agreements"] as! String
                    let crumbcount = userinfo["crumbCount"] as! Int
                    
                    
                    
                    self.NSUserData.setValue(1, forKey: "badgeOther")
                    self.NSUserData.setValue(crumbcount, forKey: "crumbCount")// let cCount = NSUserData.integerForKey("crumbCount")
                    self.NSUserData.setValue(agree, forKey: "didAgreeToPolAndEULA")
                    self.NSUserData.setValue(userName, forKey: "userName")
                    self.NSUserData.setValue(premiumStatus, forKey: "premiumStatus")
                    self.NSUserData.setValue(recordName, forKey: "recordName")
                    self.NSUserData.setValue(banned, forKey: "banned")
                }
            }else{
                print(error!)
            }
        }
        
    }
    //MARK: save icloud msgs to coreData
    
    func timerForLoadAndStore(){
        if (timerRepeatLoadAndStore == nil) && (checkLocation()) {
            print("timerForLoadAndStore")
            //checks icloud every 90 sec for a msg
            timerRepeatLoadAndStore = Timer.scheduledTimer(timeInterval: 80, target: self, selector: #selector(AppDelegate().loadAndStoreiCloudMsgsBasedOnLoc), userInfo: nil, repeats: true)
        }
    }
    
    //constant checking for new msgs
    
    //this is the heart of the app
    
    //does not run in background, gets queued then runs after returning to foreground, try p
    func loadAndStoreiCloudMsgsBasedOnLoc(){// load icloud msgs; need to check if msg is already loaded & store loaded msgs to persist between views and app instances
        //I need to wait before running this stuff get better accuracy data ->
        
        self.locationManager.startUpdatingLocation()
        
        let currentUserLoc = bestCurrent
        var locAge = 31.0
        
        if currentUserLoc != nil{
            locAge = -Double((currentUserLoc?.timestamp.timeIntervalSinceNow)!)
        }
        
        if currentUserLoc != nil && ((locAge) < 30.0 ){
            
            let radiusKm = 70 / 1000.0//30=~100ft,40=131ft
            let predicate: NSPredicate = NSPredicate(format: "distanceToLocation:fromLocation:(%K,%@) < %f", "location", currentUserLoc!, radiusKm)
            let query = CKQuery(recordType: "CrumbMessage", predicate: predicate)
            helperfunctions.loadIcloudMessageToCoreData(query)
            
            helperfunctions.testStoredMsgsInArea(currentUserLoc!)
            
            print("load and store has run")
            return
            
        }else if currentUserLoc == nil{
            print("location failure")
            return
        }
    }
    
    func lookForMessagesRefresh(){// load icloud msgs; need to check if msg is already loaded & store loaded msgs to persist between views and app instances
        //I need to wait before running this stuff get better accuracy data ->
        
        let currentUserLoc = locationManager.location

        
        if currentUserLoc != nil{
            
            let radiusKm = 80 / 1000.0//30=~100ft,40=131ft
            let predicate: NSPredicate = NSPredicate(format: "distanceToLocation:fromLocation:(%K,%@) < %f", "location", currentUserLoc!, radiusKm)
            let query = CKQuery(recordType: "CrumbMessage", predicate: predicate)
            helperfunctions.loadIcloudMessageToCoreData(query)
            
            helperfunctions.testStoredMsgsInArea(currentUserLoc!)
            
            print("lookForMessagesRefresh just ran")
            return
            
        }else if currentUserLoc == nil{
            print("location failure")
            return
        }
    }
    
    
    //MARK: Location Stuff
    
    
    func initLocationManager() {
        //DispatchQueue.main.async(execute: { () -> Void in
            self.seenError = false
            self.locationFixAchieved = false
            self.locationManager = CLLocationManager()
            self.locationManager.delegate = self
            self.locationManager.requestAlwaysAuthorization()
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.allowsBackgroundLocationUpdates = true
            self.locationManager.startUpdatingLocation()
        //})
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {//this was hard to make
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        let newloc = locations.last
        let locationAge = -((newloc?.timestamp.timeIntervalSinceNow)!)
        
        if Double(locationAge) > 5.0 {return}//if old try again with newest variable
        if Double((newloc?.horizontalAccuracy)!) < 0 {return}// error value

        var bestCurrentTime = 0.0
        if bestCurrent != nil{
            bestCurrentTime = -Double((bestCurrent?.timestamp.timeIntervalSinceNow)!)
            if bestCurrentTime < 60.0{
                return
            }
        }
        if bestEffortAtLocation == nil || (bestEffortAtLocation.horizontalAccuracy > (newloc?.horizontalAccuracy)!) || bestCurrentTime > 61.0{
            //if best is empty 
            //if new value is more accurate
            //if bestcurrent is old as fuck
            // store new value
            self.bestEffortAtLocation = newloc
            /*var bestCurrentTime = 0.0
            if bestCurrent != nil{
                bestCurrentTime = Double((bestCurrent?.timestamp.timeIntervalSinceNow)!)
            }*/
            // test the measurement to see if it meets the desired accuracy
            if ((bestEffortAtLocation?.horizontalAccuracy)! <= 10.0) || (bestCurrentTime > 60.0){
                // we have a measurement that meets our requirements, so we can stop updating the location
                //
                // IMPORTANT!!! Minimize power usage by stopping the location manager as soon as possible.
                //
                bestCurrent = bestEffortAtLocation
                self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            }
            
        }
    }
    
    func checkLocation() -> Bool{
        if locationManager.location != nil{
            return true
        } else{
            return false
        }
    }
    
    // Location Manager Delegate stuff
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print(error)
    }
    
    /*I think this is his http://stackoverflow.com/a/24696878 */
    
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
    //***********************************************************************************************************************//
    
    //MARK: Further cloudkit functions
    func isICloudContainerAvailable()->Bool {
        if FileManager.default.ubiquityIdentityToken != nil {
            return true
        }
        else {
            return false
        }
    }
    
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
        
        let crumblimit = 7
        
        if cCount < crumblimit && Lastdate?.description != nil{//extra hour is sneeking its way in here soumehow
            
            var oldExcess = NSUserData.object(forKey: "excesstime") as? Double//excess 'seconds' from last check
            
            if oldExcess == nil {//if blank give it zero
                oldExcess = 0.0
            }
            
            let timeElapsedh = Int((-Lastdate!.timeIntervalSinceNow + oldExcess!) / 3600)//converts nsdate to time elapsed in hours
            let excess = round((-Lastdate!.timeIntervalSinceNow + oldExcess!).truncatingRemainder(dividingBy: 3600))
            
           // print("hours elapsed:\(timeElapsedh) extra seconds stored:\(round(oldExcess!)) s")
            if timeElapsedh + cCount <= crumblimit && timeElapsedh >= 1 {
                cCount = cCount + timeElapsedh
                self.NSUserData.setValue(cCount, forKey: "crumbCount")
                UpdateCrumbCount(cCount)
            }else if cCount + timeElapsedh > crumblimit {
                cCount = crumblimit
                NSUserData.setValue(cCount, forKey: "crumbCount")
                UpdateCrumbCount(cCount)
            }
            
            self.NSUserData.setValue(excess, forKey: "excesstime")//unused seconds from this check
            
            self.NSUserData.setValue(Date(), forKey: "SinceLastCheck")
            
        }
     
     }
    func UpdateCrumbCount(_ cCount: Int){
        
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        let CKuserID: CKRecordID = CKRecordID(recordName: NSUserData.string(forKey: "recordID")!)//keychain
        
        let query = CKQuery(recordType: "UserInfo", predicate: NSPredicate(format: "%K == %@", "creatorUserRecordID" ,CKReference(recordID: CKuserID, action: CKReferenceAction.none)))
        
        publicData.perform(query, inZoneWith: nil) {
            results, error in
            if error == nil{
                for userinfo in results! {//need to have this update if user has already signed in before
                    userinfo.setValue(cCount, forKey: "crumbCount")
                    publicData.save(userinfo, completionHandler: {theRecord, error in
                        if error == nil{
                            print("updated crumbcount")
                        }else{
                            print(error as Any)
                        }
                    })
                }
            }else{
                print(error!)
            }
        }
        
    }

    //MARK: User Notifications
    
    //remote Notification funcs for subscriptions
    
    
    //this func it pretty dumb, so I get a notif when a any breadcrumb changes(it includes the recordid)
    //but it does not tell me what specific value has changed
    //so i just update the only two that can, comment and vote
    //at least to my knowledge this is how it works
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        
        let cloudKitNotification = CKNotification.init(fromRemoteNotificationDictionary: userInfo as! [String : NSObject])
        
        //let alertBody = cloudKitNotification.alertBody//123
        //print(alertBody!)
        print("recieved notif")
        if cloudKitNotification.notificationType == .query {
            if cloudKitNotification.alertBody == "Somebody upvoted on one of your Crumbs, Congrats!"{
                let recordID = (cloudKitNotification as! CKQueryNotification).recordID
                let voteValue = (cloudKitNotification as! CKQueryNotification).recordFields?.first?.value as? Int
                
                helperfunctions.updateCrumbFromSub(recorduuid: recordID!, NewVote: voteValue)
                
            }else if cloudKitNotification.alertBody == "Someone commented on your Crumb check it out!"{
                let recordID = (cloudKitNotification as! CKQueryNotification).recordFields?.first?.value as? CKReference
                //print((cloudKitNotification as! CKQueryNotification).recordFields)
                if let id = recordID?.recordID{
                    helperfunctions.getcommentcktocd(ckidToTest: id)
                }else{
                    helperfunctions.updateTableViewcomments()//updates all
                }
            }
            completionHandler(.newData)
        }
        
    }
    
    //user Notification funcs function for load and store
    
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("run")
        
        let dictionary = response.notification.request.content.userInfo
        let recordid = dictionary["RecordUuid"] as? String
        let userid = dictionary["UserId"] as? String
        
        
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier && recordid != nil{
            notifTakeToCrumb(userid: userid!, recordid: recordid!)
        }
        completionHandler()
    }
    
    
    
    func notifTakeToCrumb(userid: String, recordid: String){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let initialViewController = storyboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
        
        if userid != NSUserData.string(forKey: "recordID"){//need to open into view crumbs but idk how
            initialViewController.selectedIndex = 2
            self.window?.rootViewController = initialViewController
            
            let others = initialViewController.selectedViewController as! OthersCrumbsTableViewController
            
            let segue = UIStoryboardSegue(identifier: "othersviewcrumb", source: others, destination: ViewCrumbViewController() as UIViewController)
            
            let upcoming = segue.destination as! ViewCrumbViewController
            
            let crumbmsg = helperfunctions.getSpecific(recorduuid: recordid)
            
            upcoming.viewbreadcrumb = crumbmsg
            
            upcoming.delegate = others
            
        }
    }
    
    func notify(title: String ,body: String, crumbID: String, userId: String) {//used in load and store
        let requestIdentifier = "ARequestId" //identifier is to cancel the notification request
        print("notify run")
        //use crumbid to know which viewcrumb to open
        if #available(iOS 10.0, *) {
            
            let badgeNumber = UIApplication.shared.applicationIconBadgeNumber
            
            
            let content = UNMutableNotificationContent()
            //content.categoryIdentifier = "CALLINNOTIFICATION"
            content.title = title
            content.body = body
            content.sound = UNNotificationSound.default()
            content.userInfo = ["RecordUuid": crumbID, "UserId": userId]
            let newbadge = 1 + badgeNumber
            content.badge = newbadge as NSNumber?
            
            // Deliver the notification in five seconds.
            
            let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 5.0, repeats: false)
            let request = UNNotificationRequest(identifier:requestIdentifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().delegate = self
            UNUserNotificationCenter.current().add(request){(error) in
                
                print("notification sent")
                if (error != nil){
                    
                    print(error?.localizedDescription ?? "error in notify")
                }
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
        
        //self.NSUserData.setValue(0, forKey: "counterLoc")
        timerForLoadAndStore()//starts checking for messages with load and store if needed
        
        AddCrumbCount()
        CDStack.saveContext()

    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        accountStatus()

        if NSUserData.string(forKey: "recordID") != nil{
            getUserInfo()

        }
        
        let oneBigTest = isICloudContainerAvailable() && NSUserData.bool(forKey: "ckAccountStatus") && NSUserData.string(forKey: "didAgreeToPolAndEULA") == "Agree" && NSUserData.string(forKey: "welcomeValue") == "welcome"
        
        if TestIfUserSignedIn(){
            
            UIApplication.shared.applicationIconBadgeNumber = 0

            AddCrumbCount()
            
            getUserInfo()
            
            initLocationManager()
            
            timerForLoadAndStore()//starts checking for messages with load and store if needed
            
            helperfunctions.updateTableViewVoteValues()//updates all votes
            helperfunctions.checkMarkedForDeleteCD()//deletes old markeds
            
            if YourCrumbsTableViewController().timerload != nil{
                YourCrumbsTableViewController().timerload?.invalidate()
            }
            
            
            
            /*no let us sit down and I shall tell ye a story. As I was writing updatetableviewcomments something strange happened. The entire app broke. Somehow, I had failed to notice that the update to ios 10 and swift 3 made inert my coredata code and brought to light some threading issues I had programmed. I am indeed an inexperienced ios programmer. I went from lead to lead, breaking the app one way and another trying to figure out the why and the what that caused my app to fail. Initially i thought it was my datamodel, and/or that my nsobject classes were getting confused with older versions of themselves. then after that debaucle I started reading about managed object contexts and how they work, after fucking with that thinking it was the core problem(it was really just a symptom) I discovered threads, and after learning how they worked; I could see that lots of my coredata code was sitting in completion handlers which run in a thread other than the main one. from there debuging all my poorly written code has been relatively easy. */
            
            //if i figure out subscriptions, this will be unnecessary
            //helperfunctions.updateTableViewcomments()//this fucks my shit up so hard
            
            //should use delegation or something
            NotificationCenter.default.post(name: Notification.Name(rawValue: "load"), object: nil)//reloads crmessages from cd everywhere


/*            UNUserNotificationCenter.current().getDeliveredNotifications(completionHandler: { (no) in
                print(no)
            })
*/
        } else if !isBanned(){
            self.window = UIWindow(frame: UIScreen.main.bounds)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            
            let initialViewController = storyboard.instantiateViewController(withIdentifier: "Banned")
            
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
        }else if NSUserData.bool(forKey: "didSegueAwayAgreement") {
            
            NSUserData.setValue(false, forKey: "didSegueAwayAgreement")
            
            self.window = UIWindow(frame: UIScreen.main.bounds)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            let initialViewController = storyboard.instantiateViewController(withIdentifier: "Agreement")
            
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
            print("Agreement")
            
            
        }else if (forKey: "didAgreeToPolAndEULA") != "Agree" && NSUserData.string(forKey: "welcomeValue") == "welcome"{
            if NSUserData.string(forKey: "recordID") == nil/*|| user != signedIn*/{//keychain
                iCloudUserIDAsync() {
                    recordID, error in
                    if let userID = recordID?.recordName {
                        print("received iCloudID \(userID)")
                        self.NSUserData.setValue(userID, forKey: "recordID")//switch to keychain?
                        self.getUserInfo()
                        //checks crumbcount and populates it, populates premium with most recent value
                    } else {
                        print("Fetched iCloudID was nil")
                    }
                }
            }
            
            self.window = UIWindow(frame: UIScreen.main.bounds)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            let initialViewController = storyboard.instantiateViewController(withIdentifier: "Agreement")
            
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
            print("sign in")
        
        
        }else if oneBigTest{
            
            //gets and sets userrecordID
            if NSUserData.string(forKey: "recordID") == nil/*|| user != signedIn*/{//keychain
                iCloudUserIDAsync() {
                    recordID, error in
                    if let userID = recordID?.recordName {
                        print("received iCloudID \(userID)")
                        self.NSUserData.setValue(userID, forKey: "recordID")//switch to keychain?
                        self.getUserInfo()
                        //checks crumbcount and populates it, populates premium with most recent value
                    } else {
                        print("Fetched iCloudID was nil")
                    }
                }
            }
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ReloadSignIn"), object: nil)
            
            self.window = UIWindow(frame: UIScreen.main.bounds)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            let initialViewController = storyboard.instantiateViewController(withIdentifier: "SignIn")
            
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
        }else if NSUserData.bool(forKey: "didAuthorize"){
        
            NSUserData.setValue(false, forKey: "didAuthorize")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ReloadSignIn"), object: nil)
            
            self.window = UIWindow(frame: UIScreen.main.bounds)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            let initialViewController = storyboard.instantiateViewController(withIdentifier: "SignIn")
            
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
        }else{
            
            //gets and sets userrecordID
            if NSUserData.string(forKey: "recordID") == nil/*|| user != signedIn*/{//keychain
                iCloudUserIDAsync() {
                    recordID, error in
                    if let userID = recordID?.recordName {
                        print("received iCloudID \(userID)")
                        self.NSUserData.setValue(userID, forKey: "recordID")//switch to keychain?
                        self.getUserInfo()
                        
                        self.NSUserData.setValue(Date(), forKey: "SinceLastCheck")

                        //checks crumbcount and populates it, populates premium with most recent value
                    } else {
                        print("Fetched iCloudID was nil")
                    }
                }
            }
            
            self.window = UIWindow(frame: UIScreen.main.bounds)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            let initialViewController = storyboard.instantiateViewController(withIdentifier: "Welcome") as! WelcomeViewController
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
            print("welcome")
        }

        //When app is reopened check cloudkit for updated vote values for crumbs that are still alive
    }
    
    func applicationWillTerminate(_ application: UIApplication) {//when app terminates terminate timers and look for large loc changes
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:
        
        CDStack.saveContext()
        //self.saveContext()
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}
