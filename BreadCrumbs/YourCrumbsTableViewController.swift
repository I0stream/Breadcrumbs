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

class YourCrumbsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NewOthersCrumbsViewControllerDelegate/*, updateViewDelegate*/ {

    //MARK: Properties
    @IBOutlet weak var YourTableView: UITableView!

    let locationManager: CLLocationManager = AppDelegate().locationManager
    let helperFunctions = AppDelegate().helperfunctions
    var crumbmessages = [CrumbMessage]()// later we will be able to access users current crumbs from the User class; making sure the msg is associated by it's uuid

    //let managedObjectContext = AppDelegate().getContext() //broke
    let NSUserData = UserDefaults.standard
    var count: Int = 0
    
    //cell height stuff
    var cellHeights = [CGFloat?]()
    let heightspacer: CGFloat = UIScreen.main.bounds.height * 0.35
    
    
    //is indicator visible?
    var indicatorAlive = false

    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(YourCrumbsTableViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        
        return refreshControl
    }()
    //var voteAtLoad = [Int?]()
    var whohasvoted = [CrumbMessage?]()//store recuuids and update in view did dis
    
    //var voteListAtView = [Int?]()
    
    //@IBOutlet weak var CrumbCountBBI: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.YourTableView.delegate = self
        self.YourTableView.dataSource = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(YourCrumbsTableViewController.loadList(_:)),name:NSNotification.Name(rawValue: "load"), object: nil)

        //loadyours

        //get ID
        //self.getUserInfo()
        
        self.crumbmessages += helperFunctions.loadCoreDataMessage(true)!//true to load yours
        //self.voteAtLoad = crumbmessages.map{$0.hasVoted}
        //print(voteAtLoad)
        //YourTableView.refreshControl?.addTarget(self, action: #selector(YourCrumbsTableViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        
        self.YourTableView.addSubview(self.refreshControl)
        
        YourTableView.estimatedRowHeight = 200
        YourTableView.rowHeight = UITableViewAutomaticDimension

        
        NotificationCenter.default.addObserver(self, selector: #selector(YourCrumbsTableViewController.listenForBackground), name: NSNotification.Name(rawValue: "UIApplicationDidEnterBackgroundNotification"), object: nil)
        
        //NotificationCenter.default.addObserver(self, selector: #selector(YourCrumbsTableViewController.reloadBasedOnRemoteNotif(_:recordID:)), name: Notification.Name(rawValue: "NotifLoad"), object: nil)
        
       
        //AppDelegate().notify(title: "test", body: "test", crumbID: crumbmessages[0].uRecordID!, userId: crumbmessages[0].senderuuid)
    }
    override func viewDidAppear(_ animated: Bool) {
        self.refreshControl.didMoveToSuperview()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        for crumb in whohasvoted{
            print("update")
            
            self.helperFunctions.crumbVote((crumb?.hasVoted!)!, crumb: crumb!, voteValue: (crumb?.intermediaryVotingValue!)! )//has voted nil when just loaded
        }
        whohasvoted.removeAll()
        
    }
    
    func listenForBackground(){
        for crumb in whohasvoted{
            print("update")
            
            self.helperFunctions.crumbVote((crumb?.hasVoted!)!, crumb: crumb!, voteValue: (crumb?.intermediaryVotingValue!)! )//has voted nil when just loaded
        }
        
        whohasvoted.removeAll()

    }
    
    
    
    // prepare view with object data;
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "yourMsgSegue") && crumbmessages.count != 0 {
            let upcoming = segue.destination as! ViewCrumbViewController
            
            let indexPath = self.YourTableView.indexPathForSelectedRow!
            let crumbmsg = crumbmessages[indexPath.row]
            
            upcoming.conHeight = 20 + (self.tabBarController?.tabBar.frame.size.height)!
            
            upcoming.viewbreadcrumb = crumbmsg
            
            let destVC = segue.destination as! ViewCrumbViewController
            destVC.delegate = self
        } else if segue.identifier == "ViewImageYourSegue"{
            let upcoming = segue.destination as!ImageViewerViewController
            
            let row = (sender as! UIButton).tag
            let crumbmsg = crumbmessages[row]
            
            upcoming.theImage = crumbmsg.photo

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
            
            // Fetches the appropriate msg for the data source layout.
            let crumbmsg = crumbmessages[indexPath.row]
            crumbmessages[indexPath.row].inscreen = false
            if crumbmsg.photo == nil{//no photo
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "YourMsgCell", for: indexPath) as! YourCrumbsTableViewCell
                
                
                //sets the values for the labels in the cell, time value and location value
                cell.TextViewCellOutlet.text = crumbmsg.text
                cell.TextViewCellOutlet.font = UIFont.systemFont(ofSize: 16)

                
                //setColorVoteButton
                if crumbmsg.hasVoted == 1{//user has voted
                    cell.VoteButton.setImage(#imageLiteral(resourceName: "likeHeartfilled"), for: .normal)
                    
                }else if crumbmsg.hasVoted == 0{
                    cell.VoteButton.setImage(#imageLiteral(resourceName: "likeHeartEmpty"), for: .normal)
                }
                //sets the values for the labels in the cell, time value and location value
                
                cell.VoteValue.text = "\(crumbmsg.votes)"
                cell.YouTheUserLabel.text = crumbmsg.senderName

                
                var textwidth = cell.YouTheUserLabel.intrinsicContentSize.width
                let contentwidth = UIScreen.main.bounds.width - 70//screen width minus total constraints and item widths + 15 padding
                if textwidth > contentwidth{
                    while textwidth > contentwidth {
                        cell.YouTheUserLabel.font = cell.YouTheUserLabel.font.withSize((cell.YouTheUserLabel.font.pointSize-1))
                        textwidth = cell.YouTheUserLabel.intrinsicContentSize.width
                    }
                }
                
                //cell.YouTheUserLabel.font = UIFont.
                cell.TimeRemainingValueLabel.text = crumbmsg.timeRelative()//time is how long ago it was posted, dont see the point to change var name to something more explanatory right now
                
                cell.VoteButton.tag = indexPath.row
                cell.VoteButton.addTarget(self, action: #selector(YourCrumbsTableViewController.buttonActions), for: .touchUpInside)
                
                if crumbmsg.calculate() > 0 {
                    let ref = Int(crumbmsg.calculate())
                    
                    let uicolorNormal = UIColor(red: 146/255, green: 144/255, blue: 144/255, alpha: 1)
                    cell.timeCountdown.textColor = uicolorNormal
                    
                    if ref >= 1 {
                        cell.timeCountdown.text! = "\(ref)h left"//////////////////////////////////////////////////
                    }else {
                        cell.timeCountdown.text! = "Nearly Done!"
                    }
                } else{
                    cell.timeCountdown.text! = "Time's up!"
                    
                    //Time's up indication Red Color
                    let uicolor = UIColor(red: 225/255, green: 50/255, blue: 50/255, alpha: 1)
                    cell.timeCountdown.textColor = uicolor
                    //
                }
                
                return cell
            }else {//photo
                let cell = tableView.dequeueReusableCell(withIdentifier: "YourPhotoCell", for: indexPath) as! ImageMessageTableViewCell
                
                cell.ReportButton.isHidden = true
                
                
                cell.UserUploadedPhotoUIView.contentMode = .scaleAspectFill
                cell.UserUploadedPhotoUIView.image = crumbmsg.photo
                cell.imageButton.tag = indexPath.row
                cell.imageButton.addTarget(self, action: #selector(YourCrumbsTableViewController.imageSeggy), for: .touchUpInside)
                
                cell.UserUploadedPhotoUIView.layer.cornerRadius = 5.0
                cell.UserUploadedPhotoUIView.clipsToBounds = true
                
                                
                //sets the values for the labels in the cell, time value and location value
                cell.TextViewCellOutlet.text = crumbmsg.text
                cell.TextViewCellOutlet.font = UIFont.systemFont(ofSize: 16)

                //setColorVoteButton
                if crumbmsg.hasVoted == 1{//user has voted
                    cell.VoteButton.setImage(#imageLiteral(resourceName: "likeHeartfilled"), for: .normal)
                    
                }else if crumbmsg.hasVoted == 0{
                    cell.VoteButton.setImage(#imageLiteral(resourceName: "likeHeartEmpty"), for: .normal)
                }
                
                //sets the values for the labels in the cell, time value and location value
                
                cell.VoteValue.text = "\(crumbmsg.votes)"
                cell.YouTheUserLabel.text = crumbmsg.senderName

                var textwidth = cell.YouTheUserLabel.intrinsicContentSize.width
                let contentwidth = UIScreen.main.bounds.width - 70//screen width minus total constraints and item widths + 15 padding
                if textwidth > contentwidth{
                    while textwidth > contentwidth {
                        cell.YouTheUserLabel.font = cell.YouTheUserLabel.font.withSize((cell.YouTheUserLabel.font.pointSize-1))
                        textwidth = cell.YouTheUserLabel.intrinsicContentSize.width
                    }
                }
                
                //cell.YouTheUserLabel.font = UIFont.
                cell.TimeRemainingValueLabel.text = crumbmsg.timeRelative()//time is how long ago it was posted, dont see the point to change var name to something more explanatory right now
                
                cell.VoteButton.tag = indexPath.row
                cell.VoteButton.addTarget(self, action: #selector(YourCrumbsTableViewController.buttonActions), for: .touchUpInside)
                
                
                
                if crumbmsg.calculate() > 0 {
                    let ref = Int(crumbmsg.calculate())
                    
                    let uicolorNormal = UIColor(red: 146/255, green: 144/255, blue: 144/255, alpha: 1)
                    cell.timeCountdown.textColor = uicolorNormal
                    
                    if ref >= 1 {
                        cell.timeCountdown.text! = "\(ref)h left"//////////////////////////////////////////////////
                    }else {
                        cell.timeCountdown.text! = "Nearly Done!"
                    }
                } else{
                    cell.timeCountdown.text! = "Time's up!"
                    
                    //Time's up indication Red Color
                    let uicolor = UIColor(red: 225/255, green: 50/255, blue: 50/255, alpha: 1)
                    cell.timeCountdown.textColor = uicolor
                    //
                }
                
                return cell

            }

        }
    }
    

    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            
            let crumbmsg = crumbmessages[indexPath.row]
            
            let id = crumbmsg.uRecordID
            
            self.helperFunctions.coreDataDeleteCrumb(id!/*, manx: AppDelegate().CDStack.mainContext*/)   //must use something other than urecordid
            
            self.helperFunctions.cloudKitDeleteCrumb(CKRecordID(recordName: id!))//this is bad for battery, but it is better for my server so :| hmmmmmmmm
            
            crumbmessages.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            reloadTables()
        }
        
        
    }
    
    
    
    //SEGUE to imageViewer
    func imageSeggy(sender: UIButton){
        print("segue to image viewer")
        self.performSegue(withIdentifier: "ViewImageYourSegue", sender: sender)
        
    }
    
    func buttonActions(sender: UIButton){
        let row = sender.tag
        let indexPath = IndexPath(row: row, section: 1)
        let crumb = crumbmessages[indexPath.row]
        
        if crumb.calculate() > 0{
           Vote(sender: sender)
        }else{
            //noVoteIndicator()
        }
    }
    
    func Vote(sender: UIButton){
        let row = sender.tag
        let indexPath = IndexPath(row: row, section: 1)
        //is pressed
        //let cell = YourTableView.dequeueReusableCell(withIdentifier: "YourMsgCell", for: indexPath) as! YourCrumbsTableViewCell
        
        let viewbreadcrumb = crumbmessages[indexPath.row]
        var inscreen = viewbreadcrumb.inscreen
        var votevalue = 0
        //let atLoad = voteAtLoad[indexPath.row]

        if viewbreadcrumb.calculate() > 0 { //alive
            if viewbreadcrumb.hasVoted == 1 && inscreen == false{
                inscreen = true
                viewbreadcrumb.hasVoted = 0
                votevalue = -1
                viewbreadcrumb.votes = (viewbreadcrumb.votes) - 1
                
            }else if viewbreadcrumb.hasVoted == 0 && inscreen == false{//has not voted before +1
                inscreen = true
                viewbreadcrumb.hasVoted = 1
                votevalue = 1
                viewbreadcrumb.votes
                    = (viewbreadcrumb.votes) + 1
            } else if viewbreadcrumb.hasVoted == 1 && inscreen == true{
                viewbreadcrumb.hasVoted = 0
                votevalue = -1

                viewbreadcrumb.votes = (viewbreadcrumb.votes) - 1
                
            }else if viewbreadcrumb.hasVoted == 0 && inscreen == true{
                viewbreadcrumb.hasVoted = 1
                votevalue = 1
                viewbreadcrumb.votes
                    = (viewbreadcrumb.votes) + 1
            }
            viewbreadcrumb.intermediaryVotingValue = votevalue
            
            //how do i say
            //if current value == 1 and they change to -1 then 1 again
            //it stores it as +1 again, updating with an extra value
            
            
            //if
            
            if let i = whohasvoted.index(where: { $0?.uRecordID == viewbreadcrumb.uRecordID }) {//test if value is in it yet
                whohasvoted.remove(at: i)
                //whohasvoted[i] = viewbreadcrumb
                print("repeat delete")
                
            }else{
 
                whohasvoted.insert(viewbreadcrumb, at: 0)
                print("new")
            }
            
            DispatchQueue.main.async(execute: { () -> Void in
                
                self.YourTableView.reloadData()
            })
        }else{ //if dead
            //noVoteIndicator()
        }

    }
    

    
    //******************************************** Will want to reload votes *****************************************************

    func loadList(_ notification: Notification){//yayay//This solves the others crumbs problem i think
        crumbmessages.removeAll()
        self.crumbmessages = helperFunctions.loadCoreDataMessage(true)!//true to load yours//is only loading one and not looping thorugh crumbs
        //self.crumbmessages)
        
        //print("loading in loadlist")
        //crumbNumUpdater()
        DispatchQueue.main.async(execute: { () -> Void in
            self.YourTableView.reloadData()
            
        })
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
    func addNewMessage(_ newCrumb: CrumbMessage) {
        
        crumbmessages.insert(newCrumb, at: 0)
        reloadTables()
    }
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        
        /*if let x = view.viewWithTag(5) {//if there is a view un animate it
            UNanimateInfoBar()
        }*/
        
        reloadCrumbs()
        refreshControl.endRefreshing()
    }
    
    func reloadCrumbs(){
        DispatchQueue.main.async(execute: { () -> Void in
            
            self.crumbmessages = self.helperFunctions.loadCoreDataMessage(true)!
            
            self.YourTableView.reloadData()
        })
    }
    
    
    @IBAction func PostButton(_ sender: AnyObject) {
        
        self.performSegue(withIdentifier: "PostButton", sender: self)
    }
    

    
    
    
    //MARK: Get User Info
    
    //check out fetchrecordwithid and maybe use the value stored in nsuserdefaults"recordID"
    /*func getUserInfo(){
        
        //get public database object
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        
        let CKuserID: CKRecordID = CKRecordID(recordName: NSUserData.string(forKey: "recordID")!)//keychain
        
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
        
    }*/

}
