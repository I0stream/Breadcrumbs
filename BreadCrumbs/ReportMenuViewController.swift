//
//  ReportMenuViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 1/25/17.
//  Copyright © 2017 Daniel Schliesing. All rights reserved.
//

import UIKit

class ReportMenuViewController: UIViewController {

    //var viewbreadcrumb: CrumbMessage?
    
    weak var delegate: reportreloaddelegate?

    
    var reportedMessageId: String?//can be comment or crumbmessage
    var reportedUserId: String?
    var typeToReport: String? //either comment or crumbmessage
    var reporteduserID: String?//can be comment or crumbmessage
    var reportedtext: String?
    
    let helperFunctions = Helper()
    
    let NSUserData = AppDelegate().NSUserData

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func goBack(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ReportTheMessage") {
            let upcoming = segue.destination as! ReportViewController
            upcoming.reportType = typeToReport
            upcoming.reportedMessageId = reportedMessageId
            
            upcoming.reportedtext = reportedtext
            upcoming.reporteduserID = reporteduserID
            //let destVC = segue.destination as! ReportViewController
            //destVC.delegate = self
            
        }
    }
    
    @IBAction func reportMessageButton(_ sender: Any) {
        //ReportTheMessage
        performSegue(withIdentifier: "ReportTheMessage", sender: self)
        //dismiss two

    }
    
    @IBAction func BlockUserButton(_ sender: Any) {
        blockUser()
        //dismiss to menu and "delete" message
    }
    
    @IBAction func RemoveContentDeleteButton(_ sender: Any){
        if typeToReport == "crumbmessage"{
            helperFunctions.markForDelete(id: reportedMessageId!)
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "load"), object: nil)//reloads crmessages from cd everywhere
            performSegue(withIdentifier: "UnwindThroughHierarchy", sender: self)
            //dismiss two
        }else if typeToReport == "comment"{
            helperFunctions.commentHide(id: reportedMessageId!)
            delegate?.reload()
            dismiss(animated: true, completion: nil)
        }
        
        //dismiss to menu and "delete" message
    }
    
    
    @IBAction func UserGuidelinesButton(_ sender: Any) {
        let url = NSURL(string : "https://breadcrumbs.social/user-guidelines/")! as URL
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url , options: ["yes" : "yes" as Any], completionHandler: { (true) in
                //print("sent to gmail")
            })
        }
    }
    
    func blockUser(){
        let userToBlock = reportedUserId
        
        var blockedUsers = NSUserData.array(forKey: "BlockedUsers") as? [String]
        if blockedUsers == nil{
            blockedUsers = [userToBlock!]
        }else{
            //print(blockedUsers)
            blockedUsers!.append(userToBlock!)
        }
        NSUserData.set(blockedUsers, forKey: "BlockedUsers")
        //NSUserData.set
        //dismiss 
        if typeToReport == "crumbmessage"{
            //reload view others
            helperFunctions.markForDelete(id: reportedMessageId!)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "load"), object: nil)//reloads crmessages from cd everywhere
            performSegue(withIdentifier: "UnwindThroughHierarchy", sender: self)
            //dimiss to others
        }else if typeToReport == "comment"{
            //and reload viewcrumb
            
            delegate?.reload()
            performSegue(withIdentifier: "UnwindThroughHierarchy", sender: self)
        }
    }
}
protocol reportreloaddelegate: class {
    func reload()
}
