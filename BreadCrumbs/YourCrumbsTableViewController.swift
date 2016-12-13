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

class YourCrumbsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NewOthersCrumbsViewControllerDelegate {

    //MARK: Properties
    @IBOutlet weak var YourTableView: UITableView!
    
    let locationManager: CLLocationManager = AppDelegate().locationManager
    let helperFunctions = Helper()
    var crumbmessages = [CrumbMessage]()// later we will be able to access users current crumbs from the User class; making sure the msg is associated by it's uuid
    var dropped = [CrumbMessage]()

    let managedObjectContext = AppDelegate().getContext() //broke
    let NSUserData = UserDefaults.standard
    var count: Int = 0
    var inscreen: Bool = false
    
    var cellHeights = [CGFloat?]()
    let heightspacer: CGFloat = UIScreen.main.bounds.height * 0.35

    //@IBOutlet weak var CrumbCountBBI: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.YourTableView.delegate = self
        self.YourTableView.dataSource = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(YourCrumbsTableViewController.loadList(_:)),name:NSNotification.Name(rawValue: "load"), object: nil)
        
        
        //navigationItem.leftBarButtonItem = editButtonItem()//will need to update icloud and coredata of delete
        
        //self.CrumbCountBBI.title = "\(String(NSUserData.stringForKey("crumbCount")!))/5"
        
        //NSTimer.scheduledTimerWithTimeInterval(60.0, target: self, selector: #selector(YourCrumbsTableViewController.crumbNumUpdater), userInfo: nil, repeats: true)//checks every 20 seconds
        
        
        //get ID
        self.getUserInfo()
        
        self.crumbmessages += helperFunctions.loadCoreDataMessage(true)!//true to load yours
        self.crumbmessages = self.crumbmessages.reversed()
        
        YourTableView.estimatedRowHeight = 200
        YourTableView.rowHeight = UITableViewAutomaticDimension
        
        AppDelegate().saveToCoreData()
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
        if (segue.identifier == "yourMsgSegue") && crumbmessages.count != 0 {
            let upcoming = segue.destination as! ViewCrumbViewController
            
            let indexPath = self.YourTableView.indexPathForSelectedRow!
            let crumbmsg = crumbmessages[indexPath.row]
            
            upcoming.viewbreadcrumb = crumbmsg
            
            let destVC = segue.destination as! ViewCrumbViewController
            destVC.delegate = self
        }
        
    }

    //MARK: DELETE CRUMB
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if crumbmessages.count == 0{
            return false
        } else{
            return true
        }
    }

    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if crumbmessages.count == 0{
            //print("no messages; do something")
            return 1
        } else{
            return crumbmessages.count + 1
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.row == crumbmessages.count && crumbmessages.count != 0 {// if last element of index
            return heightspacer
        }else if crumbmessages.count == 0{
            return 100
        }else if cellHeights.indices.contains(indexPath.row){//if we have a height for that indexpath
            //print("known")
            return cellHeights[indexPath.row]!
        }else{

            cellHeights.append(YourTableView.rowHeight)
            return YourTableView.rowHeight
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
                
            let crumbmsg = crumbmessages[indexPath.row]
                
            let id = crumbmsg.uRecordID
            helperFunctions.coreDataDeleteCrumb(id!)//must use something other than urecordid
            crumbmessages.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
        }
        

    }
    
    // MARK: - Navigation
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if crumbmessages.count != 0 && indexPath.row != crumbmessages.count{
            self.performSegue(withIdentifier: "yourMsgSegue", sender: self)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        //print("loading..")
        
        if crumbmessages.count == 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: "NoCrumbMessageYours", for: indexPath)
            return cell
        }else if indexPath.row == (crumbmessages.count){
            let cell = tableView.dequeueReusableCell(withIdentifier: "SpacerYour", for: indexPath)
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            return cell
        }else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "YourMsgCell", for: indexPath) as! YourCrumbsTableViewCell
            
            // Fetches the appropriate msg for the data source layout.
            let crumbmsg = crumbmessages[indexPath.row]
            
            //sets the values for the labels in the cell, time value and location value
            cell.TextViewCellOutlet.text = crumbmsg.text
            
            let normalColor = UIColor(red: 245/255, green: 166/255, blue: 35/255, alpha: 1)
            let bluecolor = UIColor(red: 64/255, green: 161/255, blue: 255/255, alpha: 1)
            
            //setColorVoteButton
            if crumbmsg.hasVoted == 1{//user has voted
                cell.VoteButton.setTitleColor(bluecolor, for: .normal)
                //cell.VoteButton.setTitleColor(normalColor, for: .selected)
            }else if crumbmsg.hasVoted == 0{
                cell.VoteButton.setTitleColor(normalColor, for: .normal)
                //cell.VoteButton.setTitleColor(bluecolor, for: .selected)
            }
            
            //sets the values for the labels in the cell, time value and location value
            if crumbmsg.votes != 1{
                cell.VoteValue.text = "\(crumbmsg.votes!) votes"
            } else {
                cell.VoteValue.text = "\(crumbmsg.votes!) vote"
            }
            cell.YouTheUserLabel.text = crumbmsg.senderName
            cell.YouTheUserLabel.font = UIFont.boldSystemFont(ofSize: 17)
            cell.TimeRemainingValueLabel.text = crumbmsg.timeRelative()//time is how long ago it was posted, dont see the point to change var name to something more explanatory right now
            if crumbmsg.calculate() > 0 {
                let ref = Int(crumbmsg.calculate())
                
                //This is reused in others
                cell.VoteButton.tag = indexPath.row
                cell.VoteButton.addTarget(self, action: #selector(YourCrumbsTableViewController.Vote), for: .touchUpInside)
                //indexPath
                
                if ref >= 1 {
                    cell.timeCountdown.text! = "\(ref)h left"//////////////////////////////////////////////////
                }else {
                    cell.timeCountdown.text! = "Nearly Done!"
                }
            } else{
                cell.timeCountdown.text! = "Time's up!"
                cell.VoteButton.addTarget(self, action: #selector(YourCrumbsTableViewController.noVoteIndicator), for: .touchUpInside)

            }
            
            /*if crumbmsg.addressStr != nil{
             cell.LocationPosted.text = String("\(crumbmsg.addressStr!)")
             }else {
             cell.LocationPosted.text = "Address error"
             }*/
            cell.TextViewCellOutlet.font = UIFont.systemFont(ofSize: 16)
            
            return cell

        }
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
    
    func Vote(sender: UIButton){
        let row = sender.tag
        let indexPath = IndexPath(row: row, section: 1)
        //is pressed
        //let cell = YourTableView.dequeueReusableCell(withIdentifier: "YourMsgCell", for: indexPath) as! YourCrumbsTableViewCell
        
        let viewbreadcrumb = crumbmessages[indexPath.row]
        
        if viewbreadcrumb.calculate() > 0 { //alive
            if viewbreadcrumb.hasVoted == 1 && inscreen == false{//has voted before setting vote to zero this is bad because of past structure
                inscreen = true
                viewbreadcrumb.hasVoted = 0
                viewbreadcrumb.votes! = (viewbreadcrumb.votes)! - 1
                
            }else if viewbreadcrumb.hasVoted == 0 && inscreen == false{//has not voted before +1
                inscreen = true
                viewbreadcrumb.hasVoted = 1
                viewbreadcrumb.votes!
                    = (viewbreadcrumb.votes)! + 1
            } else if viewbreadcrumb.hasVoted == 1 && inscreen == true{
                viewbreadcrumb.hasVoted = 0
                viewbreadcrumb.votes! = (viewbreadcrumb.votes)! - 1
                
            }else if viewbreadcrumb.hasVoted == 0 && inscreen == true{
                viewbreadcrumb.hasVoted = 1
                viewbreadcrumb.votes!
                    = (viewbreadcrumb.votes)! + 1
            }
            
            helperFunctions.crumbVote(viewbreadcrumb.hasVoted!, crumb: viewbreadcrumb )
            DispatchQueue.main.async(execute: { () -> Void in
                self.YourTableView.reloadData()
            })
        }else{ //if dead
            noVoteIndicator()
        }

    }
    

    
    //******************************************** Will want to reload votes *****************************************************
    func loadList(_ notification: Notification){//yayay//This solves the others crumbs problem i think
        crumbmessages.removeAll()
        self.crumbmessages += limitTotalCrumbs(helperFunctions.loadCoreDataMessage(true)!)//true to load yours//is only loading one and not looping thorugh crumbs
        //self.crumbmessages)
        
        //print("loading in loadlist")
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
    
    func noVoteIndicator(){
        let alertController = UIAlertController(title: "BreadCrumbs", message:
            "You cannot vote on a dead crumb", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func reloadTables(){
        DispatchQueue.main.async(execute: { () -> Void in
            self.YourTableView.reloadData()
        })
    }
    
    @IBAction func PostButton(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "PostButton", sender: self)
    }
    
}
