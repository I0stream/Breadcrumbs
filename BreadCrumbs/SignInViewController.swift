//
//  SignInViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 6/27/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import UIKit
import SystemConfiguration
import CloudKit


class SignInViewController: UIViewController, UITextFieldDelegate {

    let NSUserData = AppDelegate().NSUserData
    let locationManager: CLLocationManager = AppDelegate().locationManager
    let helperFunctions = Helper()//contains various cd and ck functions
    
    @IBOutlet weak var setUserNameTextField: UITextField!
    @IBOutlet weak var AView: UIView!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var ErrorDisp: UILabel!
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setUserNameTextField.delegate = self
        self.hideKeyboardWhenTappedAround()
        
        accountStatus()//does user have icloud drive enabled
        errorTest()//does user have internet service, does he have icloud enabled, and icloud drive enabled
        
        NotificationCenter.default.addObserver(self, selector: #selector(SignInViewController.loadList(_:)),name:NSNotification.Name(rawValue: "ReloadSignIn"), object: nil)
        ErrorDisp.isHidden = true
        //requestloc()
    }
    func requestloc(){
        NSUserData.setValue(true, forKey: "didAuthorize")
        locationManager.requestAlwaysAuthorization()
    }
    override func viewDidAppear(_ animated: Bool) {
        requestloc()

    }
    
    //MARK: Actions
    
    @IBAction func signUpAction(_ sender: UIButton) {
        
        if isICloudContainerAvailable() && setUserNameTextField.text?.characters.count > 0 && setUserNameTextField.text?.characters.count < 16 && NSUserData.bool(forKey: "ckAccountStatus") && currentReachabilityStatus != .notReachable && AppDelegate().isBanned(){
            
            //make a record in cloudkit if a userinfo for this account is not found

            //gets and sets userrecordID
            iCloudUserIDAsync() {
                recordID, error in
                if let userID = recordID?.recordName {
                    print("received iCloudID \(userID)")
                    //checks crumbcount and populates it, populates premium with most recent value,
                    self.NSUserData.setValue(userID, forKey: "recordID")//keychain
                } else {
                    print("Fetched iCloudID was nil")
                }
            }
            //        createUserInfo(setUserNameTextField.text!)

            
            ckUniqueNameTest(username: setUserNameTextField.text!)
            
            
            }else if AppDelegate().isBanned(){
            performSegue(withIdentifier: "BannedPage", sender: sender)
        }
        else{
            errorTest()
        }
    }
    
    func successSignIn(){
        createUserInfo(setUserNameTextField.text!)
        AppDelegate().initLocationManager()
        
        helperFunctions.cloudkitSub()//subscribe to upvotes
        helperFunctions.commentsub()//subscribe to comments
        
        self.resignFirstResponder()
        
        NSUserData.setValue(2, forKey: "otherExplainer")
        
        //if if if if if if if okie doke
        if NSUserData.integer(forKey: "otherExplainer") == 2{
            let user = "Sabre"
            let tex = "Hi! This is a BreadCrumb. It's a message that you can find in different places you go, wherever people have dropped them. You can start a conversation on any BreadCrumb by first tapping the message, then the comment button. Or drop your own crumb wherever you are by pressing the plus button."
            let userId = "_abacd--_dfasdfsiaoucvxzmnwfehk"
            self.Crumb(text: tex, User: user, senderid: userId, currentime: 1)
            //NSUserData.setValue(1, forKey: "otherExplainer")
            
        }
        
        performSegue(withIdentifier: "SignInSegue", sender: nil)//presents weird and i also want user to be able to access this and sign out/in again. cant change username after picking though. may need more view controllers
        
    }
    
    func Crumb(text: String, User: String, senderid: String, currentime: Int){
        if checkLocation() == true{
            
            
            //update crumbcount value, maybe move this to savetocloud
            if senderid == NSUserData.string(forKey: "recordID")!{
                let cCounter: Int = Int(NSUserData.string(forKey: "crumbCount")!)! - 1
                
                NSUserData.setValue(cCounter, forKey: "crumbCount")
                AppDelegate().UpdateCrumbCount(cCounter)
            }
            
            
            //init date, location for the message obj
            let date = Date()
            let curLoc = locationManager.location!
            
            
            //create crumbMessage object
            let crumbmessage = CrumbMessage(text: text, senderName: User, location: curLoc, timeDropped: date, timeLimit: currentime, senderuuid: senderid, votes: 0)
            crumbmessage?.hasVoted = 0//keychain
            
            
            WriteCrumbViewController().saveToCloudThenCD(crumbmessage)//saves both cd and ck
            
            
        } else {
            print("Tests did fail :(")/*I need to add an indicator and disable the post button if the
             tests are failing; like jesus it makes testing shit a pain in my ass whenever I sim it
             the loc services dont auto run half the time and then I have to dick around with it*/
        }
        
    }

    
    func ckUniqueNameTest(username: String){
        
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        
        let query = CKQuery(recordType: "UserInfo", predicate: NSPredicate(format: "%K == %@", "userName" ,username))
        
        publicData.perform(query, inZoneWith: nil) {
            results, error in
            if error == nil{
                if results?.count == 1{
                    print("Someone is using that username, please try a different one")
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.failMessage(text: "Someone is using that username, please try a different one")
                    })
                    
                }else if (results?.isEmpty)!{
                    print("no account found")
                    self.successSignIn()
                }
                
            }else{
                self.failMessage(text: "An error occurred please try again later :(")
                print(error!)
            }
        }
    }
    
    //MARK: Tests
    
    //length error, cloud error, internet error
    func errorTest(){
        if isICloudContainerAvailable() && NSUserData.bool(forKey: "ckAccountStatus") && currentReachabilityStatus != .notReachable && setUserNameTextField.text?.characters.count > 0 && setUserNameTextField.text?.characters.count < 16{//success
            //print("a user is signed into icloud")
            signUpButton.isEnabled = true
            ErrorDisp.isHidden = true
            
        }else if isICloudContainerAvailable() == false || NSUserData.bool(forKey: "ckAccountStatus") == false{
            
            failMessage(text: "Please sign into iCloud and enable iCloud drive")
            
        }else if currentReachabilityStatus == .notReachable{
            failMessage(text: "No service, cannot sign up without internet")
        }else if setUserNameTextField.text?.characters.count < 1 {
            
            failMessage(text: "Please enter a longer username")
            
        }else if setUserNameTextField.text?.characters.count > 15{
            
            failMessage(text: "Please enter a too long by \((setUserNameTextField.text?.characters.count)! - 15) characters")
            
        }
    }
    //fail message
    func failMessage(text: String){
        ErrorDisp.text = text
        ErrorDisp.isHidden = false
        signUpButton.isEnabled = false
    }
    

    
    func checkLocation() -> Bool{
        if locationManager.location != nil{
            return true
        } else{
            return false
        }
    }
    
    
    //MARK: Cloud authentification
    
    
    //cloudkit user authentication
    func isICloudContainerAvailable()->Bool {
        if FileManager.default.ubiquityIdentityToken != nil {
            return true
        }
        else {
            return false
        }
    }
    //accountStatus
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
    
    //MARK: Dismiss and textfield
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SignInViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        //accountStatus()//does user have icloud drive enabled
        //checkUserStatus()//does user have internet service, does he have icloud enabled, and icloud drive enabled
        view.endEditing(true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        AView.isHidden = false
        accountStatus()//does user have icloud drive enabled
        
        errorTest()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    //MARK: Notification center
    func loadList(_ notification: Notification){
        DispatchQueue.main.async(execute: { () -> Void in
            self.accountStatus()
            self.errorTest()

        })
    }

    
    //MARK: UserInfo Cloud Creation
    //idk i need it for premium but when will i do that?
    func createUserInfo(_ username: String){
        let time = Date()
        NSUserData.setValue(setUserNameTextField.text, forKey: "userName")
        NSUserData.setValue(7, forKey: "crumbCount")// let cCount = NSUserData.integerForKey("crumbCount")
        NSUserData.setValue(time, forKey: "SinceLastCheck")
        NSUserData.setValue(0, forKey: "premiumStatus")
        NSUserData.setValue(0, forKey: "badgeOther")
        
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        
        let record = CKRecord(recordType: "UserInfo")
        
        
        record.setValue("Agree", forKey: "Agreements")
        record.setValue(username, forKey: "userName")
        record.setValue(7, forKey: "crumbCount")
        record.setValue(0, forKey: "premiumStatus")
        record.setValue(0, forKey: "Reported")
        record.setValue("notBanned", forKey: "Banned")
        record.setValue(NSUserData.string(forKey: "recordID"), forKey: "UserID")
        
        publicData.save(record, completionHandler: { record, error in
            if error != nil {
                print(error.debugDescription)
            }
        })
        
    }
    
    
    func ckUserinfoTest(username: String){
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        let CKuserID: CKRecordID = CKRecordID(recordName: NSUserData.string(forKey: "recordID")!)//keychain
        
        let query = CKQuery(recordType: "UserInfo", predicate: NSPredicate(format: "%K == %@", "creatorUserRecordID" ,CKReference(recordID: CKuserID, action: CKReferenceAction.none)))
        
        publicData.perform(query, inZoneWith: nil) {
            results, error in
            if error == nil{
                if results?.count == 1{
                    print("found account")
                    let inf = results?[0]
                    inf?.setValue(username ,forKey: "userName")
                    
                    let crumbcount = inf?.value(forKey: "crumbCount") as! Int
                    let prem = inf?.value(forKey: "premiumStatus") as! Int
                    let ban = inf?.value(forKey: "Banned") as! String
                    
                    let agree = inf?.value(forKey: "Agreements") as! String
                    
                    let time = Date()
                    
                    self.NSUserData.setValue(agree, forKey: "didAgreeToPolAndEULA")
                    self.NSUserData.setValue(self.setUserNameTextField.text, forKey: "userName")
                    self.NSUserData.setValue(crumbcount, forKey: "crumbCount")// let cCount = NSUserData.integerForKey("crumbCount")
                    self.NSUserData.setValue(time, forKey: "SinceLastCheck")
                    self.NSUserData.setValue(ban, forKey: "banned")
                    self.NSUserData.setValue(prem, forKey: "premiumStatus")
                    self.NSUserData.setValue(1, forKey: "badgeOther")

                    
                    publicData.save(inf!, completionHandler: { record, error in
                        if error != nil {
                            print(error.debugDescription)
                        }
                    })
                }else if (results?.isEmpty)!{
                    print("no account found")
                    self.createUserInfo(username)
                }
                
            }else{
                print(error!)
            }
        }
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

//this too i think is his: http://stackoverflow.com/q/41414737

protocol Utilities {
}

extension NSObject:Utilities{
    
    
    enum ReachabilityStatus {
        case notReachable
        case reachableViaWWAN
        case reachableViaWiFi
    }
    
    var currentReachabilityStatus: ReachabilityStatus {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return .notReachable
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return .notReachable
        }
        
        if flags.contains(.reachable) == false {
            // The target host is not reachable.
            return .notReachable
        }
        else if flags.contains(.isWWAN) == true {
            // WWAN connections are OK if the calling application is using the CFNetwork APIs.
            return .reachableViaWWAN
        }
        else if flags.contains(.connectionRequired) == false {
            // If the target host is reachable and no connection is required then we'll assume that you're on Wi-Fi...
            return .reachableViaWiFi
        }
        else if (flags.contains(.connectionOnDemand) == true || flags.contains(.connectionOnTraffic) == true) && flags.contains(.interventionRequired) == false {
            // The connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs and no [user] intervention is needed
            return .reachableViaWiFi
        }
        else {
            return .notReachable
        }
    }
    
}
