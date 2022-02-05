//
//  ChangeUserNameViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 7/5/16.
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


class ChangeUserNameViewController: SettingsViewController, UITextFieldDelegate {
    
    @IBOutlet weak var ChangeNameField: UITextField!
    @IBOutlet weak var errorMessageLabel: UILabel!
    @IBOutlet weak var hiddenbuttonview: UIView!
    
    override func viewDidLoad() {
        //super.viewDidLoad()

        ChangeNameField.delegate = self
        errorMessageLabel.text = ""
        self.hideKeyboardWhenTappedAround()
        hiddenbuttonview.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        hiddenbuttonview.isHidden = false
        return false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {

        hiddenbuttonview.isHidden = false
        //signUpButton.hidden = false
        
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ChangeUserNameViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        hiddenbuttonview.isHidden = false

    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
    @IBAction func cancelChange(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    //the button action that changes the username
    @IBAction func ChangeNameButton(_ sender: AnyObject) {
        if ChangeNameField.text?.count < 16 && ChangeNameField.text?.count > 1{
            NSUserData.setValue(ChangeNameField.text, forKey: "userName")
            ckUniqueNameTest(username: ChangeNameField.text!)
        }else if ChangeNameField.text?.count < 1 {
            
            errorMessageLabel.text = "Please enter a longer username"
            
        }else if ChangeNameField.text?.count > 15{
            
             errorMessageLabel.text = "Please enter a too long by \((ChangeNameField.text?.count)! - 15) characters"
            
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
                    self.errormessage()
                }else if (results?.isEmpty)!{
                    print("no account found")
                    self.changeNameCK(username)
                }
                
            }else{
                self.errorMessageLabel.text = "An error occurred please try again later :("
                print(error!)
            }
        }
    }
    
    func errormessage(){
        DispatchQueue.main.async(execute: { () -> Void in
            self.errorMessageLabel.isHidden = false
            self.errorMessageLabel.text = "Someone is using that username, please try a different one"
        })
        
    }
    
    //changes username in /user whatever
    
    func changeNameCK(_ userInput: String){
        
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        let CKuserID: CKRecord.ID = CKRecord.ID(recordName: NSUserData.string(forKey: "recordID")!)//keychain
        
        let query = CKQuery(recordType: "UserInfo", predicate: NSPredicate(format: "%K == %@", "creatorUserRecordID" ,CKRecord.Reference(recordID: CKuserID, action: CKRecord.Reference.Action.none)))
        
        publicData.perform(query, inZoneWith: nil) {
            results, error in
            if error == nil{
                for userinfo in results! {//need to have this update if user has already signed in before
                    userinfo.setObject(userInput as CKRecordValue?, forKey: "userName")
                    publicData.save(userinfo, completionHandler: {theRecord, error in
                        if error == nil{
                            print("saved version")
                            self.dismiss(animated: true, completion: nil)
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
}

