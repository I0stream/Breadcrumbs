//
//  SettingsViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 5/1/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import UIKit
import CloudKit

class SettingsViewController: UIViewController, ChangeUserNameViewControllerDelegate {

    let NSUserData = AppDelegate().NSUserData
    var counter = 0
    let locationManager: CLLocationManager = AppDelegate().locationManager
    var username: String { get {return NSUserData.string(forKey: "userName")!}}
    
    
    @IBOutlet weak var usernameUILabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //setName()
        self.usernameUILabel.text = username
        
        locationManager.requestAlwaysAuthorization()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {//navigate to settings controller
        if segue.identifier == "settingId" {
            if segue.destination is ChangeUserNameViewController {
                let destVC = segue.destination as! ChangeUserNameViewController
                destVC.delegate = self
                //print(destVC.delegate.debugDescription)
            }
        }
    }

    @IBAction func settingsButton(_ sender: AnyObject) {
    }
    
    func changedUsername(_ str: String){//updates username from settingscontroller with a delegate :D
        DispatchQueue.main.async(execute: { () -> Void in
            self.usernameUILabel.text = str
        })
    }
}
