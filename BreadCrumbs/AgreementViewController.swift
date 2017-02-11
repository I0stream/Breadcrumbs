//
//  AgreementViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 1/10/17.
//  Copyright © 2017 Daniel Schliesing. All rights reserved.
//

import UIKit

class AgreementViewController: UIViewController{
    let NSUserData = AppDelegate().NSUserData

    @IBOutlet weak var explainlabelstuff: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func DoAgree(_ sender: Any) {
        NSUserData.setValue("Agree", forKey: "didAgreeToPolAndEULA")
        performSegue(withIdentifier: "Agree", sender: sender)
    }
    
    
    @IBAction func DontAgree(_ sender: Any) {
        performSegue(withIdentifier: "NoAgree", sender: sender)
    }
    
/*
    @IBAction func PrivacyPolicy(_ sender: Any) {
        let url = NSURL(string : "https://breadcrumbs.social/privacy-policy/")! as URL
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url , options: ["yes" : "yes" as Any], completionHandler: { (true) in
                //print("sent to gmail")
            })
        }
    }*/
    @IBAction func Agreement(_ sender: Any) {
        NSUserData.setValue(true, forKey: "didSegueAwayAgreement")
        let url = NSURL(string : "https://breadcrumbs.social/user-agreement/")! as URL
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url , options: ["yes" : "yes" as Any], completionHandler: { (true) in
                //print("sent to gmail")
            })
        }
    }
    
    @IBAction func UserGuidelines(_ sender: Any) {
        NSUserData.setValue(true, forKey: "didSegueAwayAgreement")
        let url = NSURL(string : "https://breadcrumbs.social/user-guidelines/")! as URL
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url , options: ["yes" : "yes" as Any], completionHandler: { (true) in
                //print("sent to gmail")
            })
        }
    }
}
