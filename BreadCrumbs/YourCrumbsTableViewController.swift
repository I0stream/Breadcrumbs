//
//  YourCrumbsTableViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 4/19/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData //need to see those stored nsmanagedObjs yo
import CloudKit

class YourCrumbsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    //MARK: Properties
    @IBOutlet weak var YourTableView: UITableView!
    
    let locationManager: CLLocationManager = AppDelegate().locationManager
    let helperFunctions = Helper()
    var crumbmessages = [CrumbMessage]()// later we will be able to access users current crumbs from the User class; making sure the msg is associated by it's uuid
    var dropped = [CrumbMessage]()

    let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext //yay
    let NSUserData = UserDefaults.standard
    var count: Int = 0
    
    //@IBOutlet weak var CrumbCountBBI: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.YourTableView.delegate = self
        self.YourTableView.dataSource = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(YourCrumbsTableViewController.loadList(_:)),name:NSNotification.Name(rawValue: "load"), object: nil)
        
        
        //navigationItem.leftBarButtonItem = editButtonItem()//will need to update icloud and coredata of delete
        
        //self.CrumbCountBBI.title = "\(String(NSUserData.stringForKey("crumbCount")!))/5"
        
        //NSTimer.scheduledTimerWithTimeInterval(60.0, target: self, selector: #selector(YourCrumbsTableViewController.crumbNumUpdater), userInfo: nil, repeats: true)//checks every 20 seconds
        
        while count == 0{// almost made infinite loop; thanks count <3
            loadSampleMessagesYours()
            count += 1
        }
        //get ID
        self.getUserInfo()
        
        self.crumbmessages += helperFunctions.loadCoreDataMessage(true)!//true to load yours
        self.crumbmessages = self.crumbmessages.reversed()
        
        YourTableView.rowHeight = UITableViewAutomaticDimension
        YourTableView.estimatedRowHeight = 95
        
    }

    //MARK: Get User Info
    
    //check out fetchrecordwithid and maybe use the value stored in nsuserdefaults"recordID"
    func getUserInfo(){
        
        //get public database object
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        
        let CKuserID: CKRecordID = CKRecordID(recordName: NSUserData.string(forKey: "recordID")!)

        let query = CKQuery(recordType: "UserInfo", predicate: NSPredicate(format: "%K == %@", "creatorUserRecordID" ,CKReference(recordID: CKuserID, action: CKReferenceAction.none)))
        
        publicData.perform(query, inZoneWith: nil) {
            results, error in
            if error == nil{
                for user in results! {
                    let crumbCountCD = user["crumbCount"] as! Int
                    let userName = user["userName"] as! String
                    let premiumStatus = user["premiumStatus"] as! Bool
                    
                    let loadedUser = UserInfo
                        .init()
                    loadedUser.userName = userName
                    loadedUser.crumbCount = crumbCountCD
                    loadedUser.premium = premiumStatus
                    
                    /*dispatch_async (dispatch_get_main_queue ()) {
                        self.CrumbCountBBI.title = "\(self.NSUserData.stringForKey("crumbCount")!)/5"
                    }*/
                }
            }else{
                print(error.debugDescription)
            }
        }
       
    }
    
    // prepare view with object data;
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "yourMsgSegue") {
            let upcoming = segue.destination as! ViewCrumbViewController
            
            let indexPath = self.YourTableView.indexPathForSelectedRow!
            let crumbmsg = crumbmessages[indexPath.row]
            
            upcoming.viewbreadcrumb = crumbmsg
        }
        
    }
    
    //MARK: Load sample msg
    func loadSampleMessagesYours() { //this method is more trouble than its worth >:(
        let locationSample: CLLocation = type(of: CLLocation()).init(latitude: 61.2181, longitude: 149.9003)
        let testMsg2 = CrumbMessage(text: "This traffic is terrible:(", senderName: NSUserData.string(forKey: "userName")!, location: locationSample, timeDropped: Date(), timeLimit: 4, senderuuid: NSUserData.string(forKey: "recordID")!, votes: 0)
        crumbmessages += [testMsg2!]
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return crumbmessages.count
    }
    
    //MARK: DELETE CRUMB
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            
            let crumbmsg = crumbmessages[indexPath.row]
            
            let id = crumbmsg.uRecordID
            helperFunctions.coreDataDeleteCrumb(id!)//must use something other than urecordid
            crumbmessages.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if (self.YourTableView.isEditing) {
            return UITableViewCellEditingStyle.delete
        }
        return UITableViewCellEditingStyle.none
    }
    
    // MARK: - Navigation
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "yourMsgSegue", sender: self)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "YourMsgCell", for: indexPath) as! YourCrumbsTableViewCell
        
        
        /*//TextView border
        cell.TextViewCellOutlet.layer.borderWidth = 1.0;
        cell.TextViewCellOutlet.layer.cornerRadius = 5.0;
        cell.TextViewCellOutlet.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).CGColor
        */
        
        // Fetches the appropriate msg for the data source layout.
        let crumbmsg = crumbmessages[indexPath.row]
        
        //sets the values for the labels in the cell, time value and location value
        cell.TextViewCellOutlet.text = crumbmsg.text
        cell.VoteValue.text = "\(crumbmsg.votes!) votes"
        cell.YouTheUserLabel.text = crumbmsg.senderName
        cell.YouTheUserLabel.font = UIFont.boldSystemFont(ofSize: 17)
        cell.TimeRemainingValueLabel.text = crumbmsg.timeRelative()//time is how long ago it was posted, dont see the point to change var name to something more explanatory right now
        if crumbmsg.calculate() > 0 {
            let ref = Int(crumbmsg.calculate())
            
            if ref >= 1 {
                cell.timeCountdown.text! = "\(ref)h left"//////////////////////////////////////////////////
            }else {
                 cell.timeCountdown.text! = "Nearly Done!"
            }
        } else{
            cell.timeCountdown.text! = "Time's up!"
        }
        
        /*if crumbmsg.addressStr != nil{
            cell.LocationPosted.text = String("\(crumbmsg.addressStr!)")
        }else {
            cell.LocationPosted.text = "Address error"
        }*/
        cell.TextViewCellOutlet.font = UIFont.systemFont(ofSize: 16)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastLoadedElement = crumbmessages.count - 1
        if indexPath.row == lastLoadedElement {
            if dropped.count >= 15{
                let fifteenMore = dropped[0...14]
                dropped = [CrumbMessage](dropped.dropFirst(15))
            
                self.crumbmessages += fifteenMore//.reverse()
            }else if dropped.count < 15 && dropped.count > 0 {
                self.crumbmessages += dropped[0...(dropped.count - 1)]
                
                dropped = [CrumbMessage]()
            }//if zero do nothing
        }
    }

    //******************************************** Will want to reload votes *****************************************************
    func loadList(_ notification: Notification){//yayay//This solves the others crumbs problem i think
        crumbmessages.removeAll()
        self.crumbmessages += limitTotalCrumbs(helperFunctions.loadCoreDataMessage(true)!)//true to load yours//is only loading one and not looping thorugh crumbs
        //self.crumbmessages)
        
        print("loading in loadlist")
        //crumbNumUpdater()
        DispatchQueue.main.async(execute: { () -> Void in
            self.YourTableView.reloadData()
            
        })
    }
    
    //updates
    /*func crumbNumUpdater(){
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.CrumbCountBBI.title = "\(String(self.NSUserData.stringForKey("crumbCount")!))/5"
        })
    }*/
    
    func limitTotalCrumbs(_ crumbs: [CrumbMessage]) -> [CrumbMessage]{
        if crumbs.count > 15{
            let remove = crumbs.count - 15
            let final = [CrumbMessage](crumbs.dropFirst(remove))
            
            dropped = [CrumbMessage](crumbs[0...(remove-1)])
            return final.reversed()
            
        }else{
            return crumbs.reversed()
        }
    }
    
    @IBAction func PostButton(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "PostButton", sender: self)
    }
    
}
