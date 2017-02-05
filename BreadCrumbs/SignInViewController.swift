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
    
    weak var timer2 = Timer()
    weak var timerload = Timer()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setUserNameTextField.delegate = self
        self.hideKeyboardWhenTappedAround()
        
        accountStatus()//does user have icloud drive enabled
        errorTest()//does user have internet service, does he have icloud enabled, and icloud drive enabled
        
        NotificationCenter.default.addObserver(self, selector: #selector(SignInViewController.loadList(_:)),name:NSNotification.Name(rawValue: "ReloadSignIn"), object: nil)
        ErrorDisp.isHidden = true
        self.timer2 = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(SignInViewController.requestloc), userInfo: nil, repeats: false)

    }
    func requestloc(){
        locationManager.requestAlwaysAuthorization()
        timer2?.invalidate()
    }
    
    //MARK: Actions
    
    @IBAction func signUpAction(_ sender: UIButton) {
        
        if isICloudContainerAvailable() && setUserNameTextField.text?.characters.count > 0 && setUserNameTextField.text?.characters.count < 17 && NSUserData.bool(forKey: "ckAccountStatus") && currentReachabilityStatus != .notReachable && AppDelegate().isBanned(){
            
            let time = Date()

            //make a record in cloudkit if a userinfo for this account is not found
            createUserInfo(setUserNameTextField.text!)
            
            NSUserData.setValue(setUserNameTextField.text, forKey: "userName")
            NSUserData.setValue(7, forKey: "crumbCount")// let cCount = NSUserData.integerForKey("crumbCount")
            NSUserData.setValue(time, forKey: "SinceLastCheck")
            NSUserData.setValue(0, forKey: "premiumStatus")
            NSUserData.setValue(0, forKey: "ExplainerCrumb")
            
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
            AppDelegate().initLocationManager()
            
            if (AppDelegate().timer1 == nil) && (checkLocation()) {
                print("running in sign in")
                //every 60 seconds runs
                timerload = Timer.scheduledTimer(timeInterval: 60.0, target: AppDelegate(), selector: #selector(AppDelegate().loadAndStoreiCloudMsgsBasedOnLoc), userInfo: nil, repeats: true)//checks icloud every 30 sec for a msg
            }
            helperFunctions.cloudkitSub()

            self.resignFirstResponder()
            
            
            performSegue(withIdentifier: "SignInSegue", sender: sender)//presents weird and i also want user to be able to access this and sign out/in again. cant change username after picking though. may need more view controllers
        }else if AppDelegate().isBanned(){
            performSegue(withIdentifier: "BannedPage", sender: sender)
        }
        else{
            errorTest()
        }
    }
    
    //MARK: Tests
    
    //length error, cloud error, internet error
    func errorTest(){
        if isICloudContainerAvailable() && NSUserData.bool(forKey: "ckAccountStatus") && currentReachabilityStatus != .notReachable && setUserNameTextField.text?.characters.count > 0 && setUserNameTextField.text?.characters.count < 17{//success
            //print("a user is signed into icloud")
            signUpButton.isEnabled = true
            ErrorDisp.isHidden = true
            
        }else if isICloudContainerAvailable() == false || NSUserData.bool(forKey: "ckAccountStatus") == false{
            
            failMessage(text: "Please sign into iCloud and enable iCloud drive")
            
        }else if currentReachabilityStatus == .notReachable{
            failMessage(text: "No service, cannot sign up without internet")
        }else if setUserNameTextField.text?.characters.count < 1 {
            
            failMessage(text: "Please enter a longer username")
            
        }else if setUserNameTextField.text?.characters.count > 16{
            
            failMessage(text: "Please enter a longer username")
            
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
        
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        
        let record = CKRecord(recordType: "UserInfo")
        
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
