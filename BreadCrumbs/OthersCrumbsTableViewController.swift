//
//  OthersCrumbsTableViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 4/28/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//
//In my heart of hearts I know for a fact, that I will need to rewrite all this damn code D':

import CloudKit
import UIKit
import CoreLocation
import CoreData

class OthersCrumbsTableViewController:  UIViewController, UITableViewDataSource, UITableViewDelegate,NewOthersCrumbsViewControllerDelegate {
    
    //i write my best code when I have no sleep
    //and by "my best code" I mean my worst code
    
    //MARK: Properties
    
    var crumbmessages = [CrumbMessage]()
    //var dropped = [CrumbMessage]()
    //var final = [CrumbMessage]()
    
    //let helperFunctions = Helper()
    let helperFunctions = AppDelegate().helperfunctions
    
    let locationManager: CLLocationManager = AppDelegate().locationManager
    let NSUserData = UserDefaults.standard
    
    var count = 0
    var cellHeights = [CGFloat?]()
    let heightspacer: CGFloat = UIScreen.main.bounds.height * 0.35
    var inscreen: Bool = false

    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(OthersCrumbsTableViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        
        return refreshControl
    }()
    
    @IBOutlet weak var OthersTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        OthersTableView.delegate = self
        OthersTableView.dataSource = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(OthersCrumbsTableViewController.reloadViewOnReopen(_:)),name:NSNotification.Name(rawValue: "load"), object: nil)
        
        // Use the edit button item provided by the table view controller.
        navigationItem.leftBarButtonItem = editButtonItem
        
        self.crumbmessages += helperFunctions.loadCoreDataMessage(false)!//false load others
        //pull to refresh observer

        self.OthersTableView.addSubview(self.refreshControl)

        OthersTableView.rowHeight = UITableViewAutomaticDimension
        OthersTableView.estimatedRowHeight = 200
    }
    /*override func viewDidDisappear(_ animated: Bool) {
        for crumbs in crumbmessages{
            crumbs.viewedOther = 1
            updateIsViewedValue(crumbs)
        }
    }*/
  


    // MARK: - Navigation
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if crumbmessages.count != 0 && indexPath.row != crumbmessages.count{
            self.performSegue(withIdentifier: "othersviewcrumb", sender: self)
        }
        
    }

    //Heights
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.row == crumbmessages.count && crumbmessages.count != 0 {// if last element of index
            return heightspacer
        }else if crumbmessages.count == 0{
            return 100
        }else if cellHeights.indices.contains(indexPath.row){//if we have a height for that indexpath
            return cellHeights[indexPath.row]!
        }else{
            //print(cellHeights.count, indexPath.row, crumbmessages.count)
            
            cellHeights.append(OthersTableView.rowHeight)
            return OthersTableView.rowHeight
        }
    }
    
    // prepare view with object data;
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if crumbmessages.count != 0 && (segue.identifier == "othersviewcrumb") {
        //set up upcoming view with crumb/object data
    
            let upcoming = segue.destination as! ViewCrumbViewController
        
            let indexPath = OthersTableView.indexPathForSelectedRow!
            let crumbmsg = crumbmessages[indexPath.row]
            
            upcoming.viewbreadcrumb = crumbmsg
  
            upcoming.delegate = self
                /*
             if crumbmsg.viewedOther == 0{
                    updateIsViewedValue(crumbmsg)
                    crumbmsg.viewedOther = 1
                    print("updated view")
             }*/
        }
        
    }
    
    
    //MARK: Load Messages
    
    // populate cell's view with object data
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if crumbmessages.count == 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: "NoCrumbMessage", for: indexPath)
            return cell
        }else if indexPath.row == (crumbmessages.count){
            let cell = tableView.dequeueReusableCell(withIdentifier: "SpacerOther", for: indexPath)
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            return cell
        }else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "OthersMsgCell", for: indexPath) as! OthersCrumbsTableViewCell
            
            let crumbmsg = crumbmessages[indexPath.row]
            
            //setColorVoteButton
            if crumbmsg.hasVoted == 1{//user has voted
                let bluecolor = UIColor(red: 64/255, green: 161/255, blue: 255/255, alpha: 1)
                cell.VoteButton.setTitleColor(bluecolor, for: .normal)
            }else if crumbmsg.hasVoted == 0{
                let normalColor = UIColor(red: 245/255, green: 166/255, blue: 35/255, alpha: 1)
                cell.VoteButton.setTitleColor(normalColor, for: .normal)
            }
            // Fetches the appropriate msg for the data source layout.
            
            //sets the values for the labels in the cell, time value and location value
            cell.TextViewCellOutlet.text = crumbmsg.text

            if crumbmsg.votes != 1{
                cell.VoteValue.text = "\(crumbmsg.votes!) votes"
            } else {
                cell.VoteValue.text = "\(crumbmsg.votes!) vote"
            }
            cell.YouTheUserLabel.text = crumbmsg.senderName
            cell.YouTheUserLabel.font = UIFont.boldSystemFont(ofSize: 17)
            cell.TimeRemainingValueLabel.text = crumbmsg.timeRelative()//time is how long ago it was posted, dont see the point to change var name to something more explanatory right now
            //This is reused in yours
            
            cell.VoteButton.tag = indexPath.row
            cell.VoteButton.addTarget(self, action: #selector(OthersCrumbsTableViewController.buttonActions), for: .touchUpInside)
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
                let uicolor = UIColor(red: 225/255, green: 0/255, blue: 0/255, alpha: 1)
                cell.timeCountdown.textColor = uicolor
                //
            }
            cell.TextViewCellOutlet.font = UIFont.systemFont(ofSize: 16)
            
            return cell
        }
    }
    
        
    //refresh table view
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        DispatchQueue.main.async(execute: { () -> Void in
            
            self.crumbmessages = self.helperFunctions.loadCoreDataMessage(false)!
            
            self.OthersTableView.reloadData()
        })
        refreshControl.endRefreshing()
    }
    
    func reloadViewOnReopen(_ notification: Notification){
        print("Loading in reload others")
        DispatchQueue.main.async(execute: { () -> Void in

            self.crumbmessages = self.helperFunctions.loadCoreDataMessage(false)!
            self.OthersTableView.reloadData()
        })
        //******************************************** Will want to reload votes *****************************************************
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    
    //MARK: DELETE CRUMB
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if crumbmessages.count == 0{
            return false
        } else{
            return true
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            
            let crumbmsg = crumbmessages[indexPath.row]
            
            let id = crumbmsg.uRecordID
            
            
            //helperFunctions.coreDataDeleteCrumb(id!/*, manx: AppDelegate().CDStack.mainContext*/)//must use something other than urecordid
            helperFunctions.markForDelete(id: id!)
            crumbmessages.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
        }
    }
    
    
    
    func buttonActions(sender: UIButton){
        let row = sender.tag
        let indexPath = IndexPath(row: row, section: 1)
        let crumb = crumbmessages[indexPath.row]
        
        if crumb.calculate() > 0{
            Vote(sender: sender)
        }else{
            noVoteIndicator()
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
                self.OthersTableView.reloadData()
            })
        }else{ //if dead
            noVoteIndicator()
        }
        
    }
    
    func noVoteIndicator(){
        let alertController = UIAlertController(title: "BreadCrumbs", message:
            "You cannot vote on a dead crumb", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: Delegation
    func reloadTables(){
        DispatchQueue.main.async(execute: { () -> Void in
            self.OthersTableView.reloadData()
        })
    }
    
    @IBAction func othersPostButton(_ sender: Any) {
        
        //let destVC = WriteCrumbViewController()
        //destVC.delegate = self
        
        self.performSegue(withIdentifier: "PostButton", sender: self)

    }
}
