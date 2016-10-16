//
//  UserStartingViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 5/1/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import UIKit
import CloudKit

class UserStartingViewController: UIViewController {

    let NSUserData = NSUserDefaults.standardUserDefaults()
    var counter = 0
    let locationManager: CLLocationManager = AppDelegate().locationManager
    
    
    @IBOutlet weak var usernameUILabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        usernameUILabel.text = NSUserData.stringForKey("userName")
    }

    override func viewDidAppear(animated: Bool) {
        
        let currentUserLoc = locationManager.location // if location changes bad things happen D:
        
        if currentUserLoc == nil && NSUserData.integerForKey("counterLoc") == 0{

            self.NSUserData.setValue(1, forKey: "counterLoc")
            let alertController = UIAlertController(title: "BreadCrumbs", message:
                "Your location services are down, posting and receiving functionallity is disabled.", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Continue?", style: UIAlertActionStyle.Default,handler: nil))
            
            presentViewController(alertController, animated: true, completion: nil)
        }
        
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "settingId" {
            if segue.destinationViewController is SettingsViewController {
                performSegueWithIdentifier("settingId", sender: sender)
            }
        }
    }
    
    
}
