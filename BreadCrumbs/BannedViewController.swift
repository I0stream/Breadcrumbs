//
//  BannedViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 1/29/17.
//  Copyright © 2017 Daniel Schliesing. All rights reserved.
//

import UIKit

class BannedViewController: UIViewController{

    let NSUserData = AppDelegate().NSUserData

    
    @IBOutlet weak var UserIDField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        UserIDField.text = "ID: \(NSUserData.string(forKey: "recordID")!)"
        //UserIDField.
        UserIDField.borderStyle = .none
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return false
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func CopyAction(_ sender: Any) {
        UIPasteboard.general.string = NSUserData.string(forKey: "recordID")!

    }
    
    @IBAction func AppealBan(_ sender: Any) {
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

}
