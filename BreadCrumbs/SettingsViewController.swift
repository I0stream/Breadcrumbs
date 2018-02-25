//
//  SettingsViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 5/1/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import UIKit
import CloudKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{

    @IBOutlet weak var settingsTableView: UITableView!
    let NSUserData = AppDelegate().NSUserData
    var counter = 0
    var username: String { get {return NSUserData.string(forKey: "userName")!}}
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 95
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0{
            UIApplication.shared.open(URL(string:UIApplicationOpenSettingsURLString)!)
        }else if indexPath.row == 1{
            changeUsername()
        }else if indexPath.row == 4{
            //print("does not work in sim")
            let url = NSURL(string : "itms-apps://itunes.apple.com/app/id1191632460")! as URL//change later
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url , options: ["yes" : "yes" as Any], completionHandler: { (true) in
                    //print("sent to gmail")
                })
            }else{
                UIApplication.shared.openURL(url)
            }
        }else if indexPath.row == 3{
            //print("does not work in sim")
            let email = "breadcrumbs.help@gmail.com"
            let url = NSURL(string: "mailto:\(email)")
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url! as URL, options: ["yes" : "yes" as Any], completionHandler: { (true) in
                    //print("sent to gmail")
                })
            }else {
                UIApplication.shared.openURL(url! as URL)
            }
        }else if indexPath.row == 2{
            let url = NSURL(string : "https://breadcrumbs.social/user-guidelines/")! as URL
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url , options: ["yes" : "yes" as Any], completionHandler: { (true) in
                    //print("sent to gmail")
                })
            }
        }else{
            NSUserData.set(nil, forKey: "BlockedUsers")
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! settingsTableViewCell

        cell.selectionStyle = .none
        
        if indexPath.row == 0{
            cell.settingLAbel.text = "Preferences for Location or Notifications"
        }else if indexPath.row == 1{
            cell.settingLAbel.text = "Change Username"
        }else if indexPath.row == 2{
            cell.settingLAbel.text = "User Guidelines"
        }else if indexPath.row == 3{//change notif state
            cell.settingLAbel.text = "Customer Support"
        }else if indexPath.row == 4{//change location state
            cell.settingLAbel.text = " Rate The App"
        }else{
            cell.settingLAbel.text = "Unblock All Users"
        }
        return cell
    }
    func changeUsername() {
        performSegue(withIdentifier: "changeUsername", sender: self)
    }
/*    @IBAction func RateAppButton(_ sender: Any) {
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
    }*/
}
