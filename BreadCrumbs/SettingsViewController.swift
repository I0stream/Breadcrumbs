//
//  SettingsViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 7/5/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import UIKit
import CloudKit

class SettingsViewController: UIViewController {

    let NSUserData = AppDelegate().NSUserData
    
    
    @IBOutlet weak var UserNameLabel: UILabel!
    @IBOutlet weak var ChangeNameField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.UserNameLabel.text = NSUserData.stringForKey("userName")


        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func changeNameCK(userInput: String){
        //take record id and use that and the new name to update ck
        let container = CKContainer.defaultContainer()
        let publicData = container.publicCloudDatabase
        
        let recordID = CKRecordID(recordName: NSUserData.stringForKey("recordID")!)
        
        publicData.fetchRecordWithID(recordID, completionHandler: {record, error in
            if error == nil{
                
                record!.setObject(userInput, forKey: "userName")
                
                publicData.saveRecord(record!, completionHandler: {theRecord, error in
                    if error == nil{
                        print("successful update!")
                        dispatch_async(dispatch_get_main_queue()) {
                            self.UserNameLabel.text = userInput
                        }
                    }else{
                        print(error)
                    }
                })
            }else{
                print(error)
            }
        })

    }
    

    @IBAction func ChangeNameButton(sender: AnyObject) {
        if ChangeNameField.text?.characters.count < 1 || ChangeNameField.text?.characters.count > 16{
            print("enter a valid username")
        }else{
            NSUserData.setValue(ChangeNameField.text, forKey: "userName")
            changeNameCK(ChangeNameField.text!)
        }
    }
    
    @IBAction func Done(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}
