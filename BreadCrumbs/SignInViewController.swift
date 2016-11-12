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
    
    @IBOutlet weak var AView: UIView!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var ErrorDisp: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setUserNameTextField.delegate = self
        self.hideKeyboardWhenTappedAround()
        
        checkUserStatus()
        // Do any additional setup after loading the view.
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SignInViewController.loadList(_:)),name:"ReloadSignIn", object: nil)
        
        ErrorDisp.hidden = true

    }
    func loadList(notification: NSNotification){//yayay//This solves the others crumbs problem i think
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.checkUserStatus()
        })
    }
    
    //cloudkit user authentication
    func checkUserStatus(){
        if NSFileManager.defaultManager().ubiquityIdentityToken != nil {
            //print("a user is signed into icloud")
            signUpButton.enabled = true
            ErrorDisp.hidden = true
        }
        else {
            ErrorDisp.text! = "Please sign into icloud and enable icloud drive"
            ErrorDisp.hidden = false
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
    func textFieldDidEndEditing(textField: UITextField) {
        AView.hidden = false
        //signUpButton.hidden = false
    }
    
    
    //MARK: Actions
    
    //sign in action
    
    @IBAction func signUpAction(sender: UIButton) {
        
        
        if  setUserNameTextField.text?.characters.count > 0 && setUserNameTextField.text?.characters.count < 21 {
            
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
            performSegueWithIdentifier("SignInSegue", sender: sender)//presents weird and i also want user to be able to access this and sign out/in again. cant change username after picking though. may need more view controllers
        }
        else if setUserNameTextField.text?.characters.count < 0 || setUserNameTextField.text?.characters.count > 21{
            ErrorDisp.text = "enter a valid length username"
            ErrorDisp.hidden = false
        } else if NSFileManager.defaultManager().ubiquityIdentityToken == nil{
            print("do nothing")
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
