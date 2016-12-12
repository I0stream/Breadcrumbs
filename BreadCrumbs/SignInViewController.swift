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
        
        NotificationCenter.default.addObserver(self, selector: #selector(SignInViewController.loadList(_:)),name:NSNotification.Name(rawValue: "ReloadSignIn"), object: nil)
        
        ErrorDisp.isHidden = true
        locationManager.requestAlwaysAuthorization()

    }
    func loadList(_ notification: Notification){//yayay//This solves the others crumbs problem i think
        DispatchQueue.main.async(execute: { () -> Void in
            self.checkUserStatus()
        })
    }
    
    //cloudkit user authentication
    func checkUserStatus(){
        if FileManager.default.ubiquityIdentityToken != nil {
            //print("a user is signed into icloud")
            signUpButton.isEnabled = true
            ErrorDisp.isHidden = true
        }
        else {
            ErrorDisp.text! = "Please sign into icloud and enable icloud drive"
            ErrorDisp.isHidden = false
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
    func textFieldDidEndEditing(_ textField: UITextField) {
        AView.isHidden = false
        //signUpButton.hidden = false
    }
    
    
    //MARK: Actions
    
    //sign in action
    
    @IBAction func signUpAction(_ sender: UIButton) {
        
        
        if  setUserNameTextField.text?.characters.count > 0 && setUserNameTextField.text?.characters.count < 21 {
            
            //make a record in cloudkit if a userinfo for this account is not found
            createUserInfo(setUserNameTextField.text!)
            //set value in nsuserdefaults
            NSUserData.setValue(setUserNameTextField.text, forKey: "userName")
            NSUserData.setValue(5, forKey: "crumbCount")// let cCount = NSUserData.integerForKey("crumbCount")
            
            NSUserData.set(0, forKey: "ExplainerCrumb")
            
            let time = Date()
            
            self.NSUserData.setValue(time, forKey: "SinceLastCheck")
            
            NSUserData.setValue(0, forKey: "premiumStatus")
            
            print("\n\(NSUserData.string(forKey: "userName")!) is my name!")
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
            
            
            performSegue(withIdentifier: "SignInSegue", sender: sender)//presents weird and i also want user to be able to access this and sign out/in again. cant change username after picking though. may need more view controllers
        }
        else if setUserNameTextField.text?.characters.count < 0 || setUserNameTextField.text?.characters.count > 21{
            ErrorDisp.text = "enter a valid length username"
            ErrorDisp.isHidden = false
        } else if FileManager.default.ubiquityIdentityToken == nil{
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
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
