//
//  SignInViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 6/27/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import UIKit
import CloudKit

class SignInViewController: UIViewController, UITextFieldDelegate {

    let NSUserData = AppDelegate().NSUserData
    
    @IBOutlet weak var setUserNameTextField: UITextField!
    
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var notifyErrorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setUserNameTextField.delegate = self
        self.hideKeyboardWhenTappedAround()
        
        checkUserStatus()
        // Do any additional setup after loading the view.
    }
    
    //cloudkit user authentication
    func checkUserStatus(){
        if NSFileManager.defaultManager().ubiquityIdentityToken != nil {
            //print("a user is signed into icloud")
        }
        else {
            print("Please sign into icloud")
            signUpButton.enabled = false
            notifyErrorLabel.text! = "Please sign into icloud"
        }
    }
 
    func createUserInfo(username: String){
        
        let container = CKContainer.defaultContainer()
        let publicData = container.publicCloudDatabase
        
        let record = CKRecord(recordType: "UserInfo")
        
        record.setValue(username, forKey: "userName")
        record.setValue(5, forKey: "crumbCount")
        record.setValue(0, forKey: "premiumStatus")
        
        
        publicData.saveRecord(record, completionHandler: { record, error in
            if error != nil {
                print(error.debugDescription)
            }
        })
        
    }
    //MARK: Actions
    
    //sign in action
    
    @IBAction func signUpAction(sender: UIButton) {
        
        
        if  setUserNameTextField.text?.characters.count > 1 && setUserNameTextField.text?.characters.count < 16 {
            
            //make a record in cloudkit if a userinfo for this account is not found
            
            createUserInfo(setUserNameTextField.text!)
            //set value in nsuserdefaults
            NSUserData.setValue(setUserNameTextField.text, forKey: "userName")
            NSUserData.setValue(5, forKey: "crumbCount")// let cCount = NSUserData.integerForKey("crumbCount")
            
            let time = NSDate()
            
            self.NSUserData.setValue(time, forKey: "SinceLastCheck")
            
            NSUserData.setValue(0, forKey: "premiumStatus")
            
            print("\n\(NSUserData.stringForKey("userName")!) is my name!")
            self.resignFirstResponder()
            
            //move these somewhere
            //***********************************************************************************************************************//
            
            AppDelegate().initLocationManager()
            
            //***********************************************************************************************************************//
            
            //has load and store run already? has autocrumbadd?
            
            //gets and sets userrecordID
            iCloudUserIDAsync() {
                recordID, error in
                if let userID = recordID?.recordName {
                    print("received iCloudID \(userID)")
                    //checks crumbcount and populates it, populates premium with most recent value,
                    self.NSUserData.setValue(userID, forKey: "recordID")
                } else {
                    print("Fetched iCloudID was nil")
                }
            }
            
            
            NSTimer.scheduledTimerWithTimeInterval(60.0, target: AppDelegate(), selector: #selector(AppDelegate().loadAndStoreiCloudMsgsBasedOnLoc), userInfo: nil, repeats: true)//checks icloud every 30 sec for a msg
            
            
            //error here, for some reason a selector is being sent to the instance and it is unrecognized
            //this is causing a shite error to be thrown and flipping the damn thing over
            //target was 'self' should be appdelegate, now fixed
            
            
            //NSTimer.scheduledTimerWithTimeInterval(1.0, target: AppDelegate() , selector: #selector(AppDelegate.checkThemAddEm), userInfo: nil, repeats: true)//checks then adds a msg every hour
            
            self.performSegueWithIdentifier("SignInSegue", sender: sender)//presents weird and i also want user to be able to access this and sign out/in again. cant change username after picking though. may need more view controllers
        }
        else if setUserNameTextField.text?.characters.count < 1 || setUserNameTextField.text?.characters.count > 16{
            print("enter a valid lengthed username")
        }
    }

    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SignInViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
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
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
}
