//
//  UserStartingViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 5/1/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import UIKit
import CloudKit

class UserStartingViewController: UIViewController, SettingsViewControllerDelegate {

    let NSUserData = AppDelegate().NSUserData
    var counter = 0
    let locationManager: CLLocationManager = AppDelegate().locationManager
    var username: String { get {return NSUserData.stringForKey("userName")!}}
    
    
    @IBOutlet weak var usernameUILabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //setName()
        self.usernameUILabel.text = username
        
        locationManager.requestAlwaysAuthorization()
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {//navigate to settings controller
        if segue.identifier == "settingId" {
            if segue.destinationViewController is SettingsViewController {
                let destVC = segue.destinationViewController as! SettingsViewController
                destVC.delegate = self
                //print(destVC.delegate.debugDescription)
            }
        }
    }

    @IBAction func settingsButton(sender: AnyObject) {
    }
    
    func changedUsername(str: String){//updates username from settingscontroller with a delegate :D
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.usernameUILabel.text = str
        })
    }
}
