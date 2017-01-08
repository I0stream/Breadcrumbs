//
//  SignInViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 6/27/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import UIKit
import CloudKit
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
        
        accountStatus()//ckstatus
        checkUserStatus()
        
        NotificationCenter.default.addObserver(self, selector: #selector(SignInViewController.loadList(_:)),name:NSNotification.Name(rawValue: "ReloadSignIn"), object: nil)
        
        ErrorDisp.isHidden = true
        locationManager.requestAlwaysAuthorization()

    }
    func loadList(_ notification: Notification){//yayay//This solves the others crumbs problem i think
        DispatchQueue.main.async(execute: { () -> Void in
            self.checkUserStatus()
        })
    }

    
    //MARK: Actions
    
    @IBAction func signUpAction(_ sender: UIButton) {
        if setUserNameTextField.text?.characters.count > 0 && setUserNameTextField.text?.characters.count < 21 && NSUserData.bool(forKey: "ckAccountStatus"){
            let time = Date()

            //make a record in cloudkit if a userinfo for this account is not found
            createUserInfo(setUserNameTextField.text!)
            
            NSUserData.setValue(setUserNameTextField.text, forKey: "userName")
            NSUserData.setValue(7, forKey: "crumbCount")// let cCount = NSUserData.integerForKey("crumbCount")
            NSUserData.setValue(time, forKey: "SinceLastCheck")
            NSUserData.setValue(0, forKey: "premiumStatus")
            NSUserData.setValue(true, forKey: "testmessage")
            NSUserData.setValue(0, forKey: "ExplainerCrumb")

            self.resignFirstResponder()
            
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
            if !(AppDelegate().timer1 == nil) && !(checkLocation()) {
                print("running in sign in")
                Timer.scheduledTimer(timeInterval: 60.0, target: AppDelegate(), selector: #selector(AppDelegate().loadAndStoreiCloudMsgsBasedOnLoc), userInfo: nil, repeats: true)//checks icloud every 30 sec for a msg
            }
            
            helperFunctions.cloudkitSub()
            
            performSegue(withIdentifier: "SignInSegue", sender: sender)//presents weird and i also want user to be able to access this and sign out/in again. cant change username after picking though. may need more view controllers
        }
        else if setUserNameTextField.text?.characters.count < 1 || setUserNameTextField.text?.characters.count > 21{
            ErrorDisp.text = "enter a valid length username"
            ErrorDisp.isHidden = false
            signUpButton.isEnabled = false
        }else if isICloudContainerAvailable() == false || NSUserData.bool(forKey: "ckAccountStatus"){
            ErrorDisp.text = "Please sign into icloud and enable icloud drive"
            ErrorDisp.isHidden = false
            signUpButton.isEnabled = false
            
        }
    }
    //MARK: Misc + tests
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SignInViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        AView.isHidden = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    func checkLocation() -> Bool{
        if locationManager.location != nil{
            return true
        } else{
            return false
        }
    }
    
    
    //MARK: Cloudkit
    //cloudkit user authentication
    func checkUserStatus(){
        if isICloudContainerAvailable(){
            //print("a user is signed into icloud")
            signUpButton.isEnabled = true
            ErrorDisp.isHidden = true
        }else if isICloudContainerAvailable() == false && NSUserData.bool(forKey: "ckAccountStatus") {
            ErrorDisp.text! = "Please sign into icloud and enable icloud drive"
            ErrorDisp.isHidden = false
            signUpButton.isEnabled = false
            
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
    
    func createUserInfo(_ username: String){
        
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        
        let record = CKRecord(recordType: "UserInfo")
        
        record.setValue(username, forKey: "userName")
        record.setValue(5, forKey: "crumbCount")
        record.setValue(0, forKey: "premiumStatus")
        
        publicData.save(record, completionHandler: { record, error in
            if error != nil {
                print(error.debugDescription)
            }
        })
        
    }

}
