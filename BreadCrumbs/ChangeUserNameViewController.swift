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


class ChangeUserNameViewController: SettingsViewController {
    
    @IBOutlet weak var UserNameLabel: UILabel!
    @IBOutlet weak var ChangeNameField: UITextField!
    @IBOutlet weak var errorMessageLabel: UILabel!
    
    var delegate: ChangeUserNameViewControllerDelegate?
    
    override func viewDidLoad() {
        //super.viewDidLoad()
        self.UserNameLabel.text = username
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func changeNameCK(_ userInput: String){
        //take record id and use that and the new name to update ck
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        
        let recordID = CKRecordID(recordName: NSUserData.string(forKey: "recordID")!)
        
        publicData.fetch(withRecordID: recordID, completionHandler: {record, error in
            if error == nil{
                
                record!.setObject(userInput as CKRecordValue?, forKey: "userName")
                
                publicData.save(record!, completionHandler: {theRecord, error in
                    if error == nil{
                        //print("successful update!")
                        DispatchQueue.main.async {
                            self.UserNameLabel.text = userInput
                        }
                    }else{
                        print(error.debugDescription)
                    }
                })
            }else{
                print(error.debugDescription)
            }
        })
    }
    
    //the button action that changes the username
    @IBAction func ChangeNameButton(_ sender: AnyObject) {
        if ChangeNameField.text?.characters.count < 1 || ChangeNameField.text?.characters.count > 16{
            errorMessageLabel.text = "enter a valid username"
        }else{
            NSUserData.setValue(ChangeNameField.text, forKey: "userName")
            changeNameCK(ChangeNameField.text!)
            
            if let del = self.delegate {
                del.changedUsername(ChangeNameField.text!)
            }
        }
    }
}
protocol ChangeUserNameViewControllerDelegate: class {
    func changedUsername(_ str: String)
}
