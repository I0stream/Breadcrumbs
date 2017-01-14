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
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
    
    @IBAction func cancelChange(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    //the button action that changes the username
    @IBAction func ChangeNameButton(_ sender: AnyObject) {
        if ChangeNameField.text?.characters.count > 16{
            errorMessageLabel.text = "Username is too long by \((ChangeNameField.text?.characters.count)! - 16) characters"
        }else if ChangeNameField.text?.characters.count < 1{
            errorMessageLabel.text = "Username is too short"
        }else{
            
            NSUserData.setValue(ChangeNameField.text, forKey: "userName")
            changeNameCK(ChangeNameField.text!)
            dismiss(animated: true, completion: nil)
        }
    }
    
    //changes username in userinfo/user whatever
    func changeNameCK(_ userInput: String){
        //take record id and use that and the new name to update ck
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        
        let recordID = CKRecordID(recordName: NSUserData.string(forKey: "recordID")!)//keychain
        
        publicData.fetch(withRecordID: recordID, completionHandler: {record, error in
            if error == nil{
                
                record!.setObject(userInput as CKRecordValue?, forKey: "userName")
                
                publicData.save(record!, completionHandler: {theRecord, error in
                    if error == nil{
                        print("successful update!")
                    }else{
                        print(error.debugDescription)
                    }
                })
            }else{
                print(error.debugDescription)
            }
        })
    }
}

