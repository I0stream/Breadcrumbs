//
//  SettingsViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 5/1/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import UIKit
import CloudKit

class SettingsViewController: UIViewController{

    let NSUserData = AppDelegate().NSUserData
    var counter = 0
    var username: String { get {return NSUserData.string(forKey: "userName")!}}
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    @IBAction func changeUsername(_ sender: AnyObject) {
        performSegue(withIdentifier: "changeUsername", sender: sender)
    }
    @IBAction func RateAppButton(_ sender: Any) {
        //print("does not work in sim")
        let url = NSURL(string : "itms-apps://itunes.apple.com/app/id1191632460")! as URL//change later
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url , options: ["yes" : "yes" as Any], completionHandler: { (true) in
                //print("sent to gmail")
            })
        }else{
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction func customerSupportButton(_ sender: Any) {
        //print("does not work in sim")
        let email = "breadcrumbs.help@gmail.com"
        let url = NSURL(string: "mailto:\(email)")
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url as! URL, options: ["yes" : "yes" as Any], completionHandler: { (true) in
                //print("sent to gmail")
            })
        }else {
            UIApplication.shared.openURL(url as! URL)
        }
    }
    
    @IBAction func UserGuidlines(_ sender: Any) {
        let url = NSURL(string : "https://breadcrumbs.social/user-guidelines/")! as URL
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url , options: ["yes" : "yes" as Any], completionHandler: { (true) in
                //print("sent to gmail")
            })
        }
    }
    @IBAction func unblockAllUsers(_ sender: Any) {
        
        NSUserData.set(nil, forKey: "BlockedUsers")
    }
}
