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

class OthersCrumbsTableViewController: UITableViewController, NewOthersCrumbsViewControllerDelegate{
    
    //i write my best code when I have no sleep
    //and by "my best code" I mean my worst code
    
    //MARK: Properties
    
    var crumbmessages = [CrumbMessage]()
    
    var dropped = [CrumbMessage]()
    var final = [CrumbMessage]()
    
    let helperFunctions = Helper()
    
    let locationManager: CLLocationManager = AppDelegate().locationManager
    //var count: Int = 0
    let NSUserData = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OthersCrumbsTableViewController.reloadViewOnReopen(_:)),name:"load", object: nil)
        
        // Use the edit button item provided by the table view controller.
        navigationItem.leftBarButtonItem = editButtonItem()
        
        loadOthersCoreDataStore()//just loads coredata objs with no smarts need to add tests
        
        //pull to refresh observer
        self.refreshControl?.addTarget(self, action: #selector(OthersCrumbsTableViewController.handleRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(self.refreshControl!)

        //load samplemsgs
        /*if count == 0{// almost made infinite loop; thanks count <3
            //loadSampleMessagesYours()
            count += 1
        }*/
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 95
    
        if locationManager.location != nil {
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil))
        }
    }
    override func viewDidDisappear(animated: Bool) {
        for crumbs in crumbmessages{
            crumbs.viewedOther = 1
            updateIsViewedValue(crumbs)
        }
    }
    
    func loadSampleMessagesYours() { //this method is more trouble than its worth >:(
        let locationSample: CLLocation = CLLocation().dynamicType.init(latitude: 61.2181, longitude: 149.9003)
        let testMsg3 = CrumbMessage(text: "Theatricality and deception are powerful agents to the uninitiated... but we are initiated, aren't we Bruce? Members of the League of Shadows! ", senderName: "The man in the mask", location: locationSample, timeDropped: NSDate(), timeLimit: 4, senderuuid: NSUserData.stringForKey("recordID")!, votes: 0)
        crumbmessages += [testMsg3!]
    }
  


    // MARK: - Navigation
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("othersviewcrumb", sender: self)
        
    }
    
    // prepare view with object data;
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        //set up upcoming view with crumb/object data
        if (segue.identifier == "othersviewcrumb") {
            let upcoming = segue.destinationViewController as! NewOthersCrumbsViewController
            
            let indexPath = self.tableView.indexPathForSelectedRow!
            let crumbmsg = crumbmessages[indexPath.row]
            
            upcoming.viewbreadcrumb = crumbmsg
            
            let destVC = segue.destinationViewController as! NewOthersCrumbsViewController
            destVC.delegate = self
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
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("othersMsgCell", forIndexPath: indexPath) as! OthersCrumbsTableViewCell
        
        let crumbmsg = crumbmessages[indexPath.row]
        
        //TextView border
        cell.othersMessageTextView.layer.borderWidth = 1.0;
        cell.othersMessageTextView.layer.cornerRadius = 5.0;
        cell.othersMessageTextView.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).CGColor
        
        // Fetches the appropriate msg for the data source layout.
        //sets the values for the labels in the cell, time value and location value
        cell.othersMessageTextView.text = crumbmsg.text
        cell.OthersVotesLabe.text = String(crumbmsg.votes!)
        cell.PosterUserNameLabel.text = crumbmsg.senderName
        cell.PosterUserNameLabel.font = UIFont.boldSystemFontOfSize(17)
        if crumbmsg.viewedOther == 0 {
            cell.IsViewedLabel.text = "NEW"
        }else{
            cell.IsViewedLabel.text = "seen"
        }
        if crumbmsg.calculate() > 0 {
            let ref = Int(crumbmsg.calculate())
            
            if ref >= 1 {
                cell.TimeCountdown.text! = "\(ref)h left"//////////////////////////////////////////////////////
            }else {
                cell.TimeCountdown.text! = "Nearly Done!"
            }
        }else{
            cell.TimeCountdown.text! = "Time's up!"
        }
        
        cell.TimeAgoPosted.text = crumbmsg.timeRelative()//time remaining not time posted
        
        /*if crumbmsg.addressStr != nil{
            cell.OthersAddress.text = String("\(crumbmsg.addressStr!)")
        }else{
            cell.OthersAddress.text = String("Address error")

        }*/
        cell.othersMessageTextView.font = UIFont.systemFontOfSize(16)
        
        /*if crumbmsg.calculate() >= 0{
            cell.IsItDeadYetLabel.text = "Alive"
        } else{
            cell.IsItDeadYetLabel.text = "DX"
        }*/
        
        return cell
    }

    
    //right now just sample msgs
    func loadOthersCoreDataStore() {
        let fmCrumbMessage = helperFunctions.loadCoreDataMessage(false)//loadsothers
        
        if fmCrumbMessage?.isEmpty != true{
            if fmCrumbMessage![0].uRecordID != nil{
                self.crumbmessages += fmCrumbMessage!
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tableView.reloadData()
                })
            }
        }
    }
    
    func updateIsViewedValue(crumb: CrumbMessage){
        //updates coredata value of viewed others, needs a reload function to complete its function
        
        let predicate = NSPredicate(format: "recorduuid == %@", crumb.uRecordID!)
        
        let fetchRequest = NSFetchRequest(entityName: "Message")
        fetchRequest.predicate = predicate
        
        do {// change it, it not work y?
            let fetchedMsgs = try helperFunctions.moc.executeFetchRequest(fetchRequest) as! [Message]
            
            let one:Int = 1
            fetchedMsgs.first?.setValue(one, forKey: "viewedOther")//is seen
            
            
            do {// save it!
                try helperFunctions.moc.save()//it is not saving
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
    }
 
    func doesArrContainUnique(CDArr: [CrumbMessage], LoadedArr: [CrumbMessage], prevDropped: [CrumbMessage])-> [CrumbMessage]{
        let bothLoadedAndDropped = LoadedArr + dropped
        
        var uniqueArr = [CrumbMessage]()
        var testArr = [CrumbMessage]()
        
        if bothLoadedAndDropped.count < CDArr.count{//
            for cdcrumbs in CDArr{
                
                for ldcrumbs in bothLoadedAndDropped{
                    
                    if ldcrumbs.uRecordID == cdcrumbs.uRecordID {//if crumb is in tableview remove from list
                        testArr.removeAll()
                        break
                        
                    }
                    testArr += [cdcrumbs]
                    
                }
                if testArr.count == bothLoadedAndDropped.count{//if a value is not found store it
                    uniqueArr += [testArr[0]]
                    break
                }
            }
            
        }
        
        let totalAmount = bothLoadedAndDropped + uniqueArr
        
        if totalAmount.count < CDArr.count{
            uniqueArr += doesArrContainUnique(CDArr, LoadedArr: totalAmount, prevDropped: dropped)
        }
        
        //return(actualAmount)
        return (uniqueArr)
        
    }
    //limit crumbs in view to 15, the brains of the operation
    func islimited(uniques: [CrumbMessage], loaded: [CrumbMessage])-> ([CrumbMessage],[CrumbMessage]){
        var total = loaded + uniques
        //var final = [CrumbMessage]()
        //var dropped = [CrumbMessage]()
        
        if total.count > 15{
            let remove = total.count - 15
            final = [CrumbMessage](total.dropFirst(remove))
            dropped = [CrumbMessage](total[0...(remove-1)])
        }
        
        return (final,dropped)
    }
    
     
    //limit crumbs in view to 15
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let lastLoadedElement = crumbmessages.count - 1
        if indexPath.row == lastLoadedElement {
            
            if dropped.count >= 15{
                let fifteenMore = dropped[0...14]
                dropped = [CrumbMessage](dropped.dropFirst(15))
                
                self.crumbmessages += fifteenMore.reverse()
            }else if dropped.count < 15 && dropped.count > 0 {
                self.crumbmessages += dropped[0...(dropped.count - 1)]
                
                dropped = [CrumbMessage]()
            }//if zero do nothing
            
        }
    }
    
    //refresh table view
    func handleRefresh(refreshControl: UIRefreshControl) {//************************************************** I DONT LIKE THIS
        let uniques = doesArrContainUnique(self.helperFunctions.loadCoreDataMessage(false)!, LoadedArr: self.crumbmessages, prevDropped: dropped)
        
        if uniques.isEmpty != true{//does this work?
            
            (final,dropped) = islimited(uniques, loaded: self.crumbmessages)
            self.crumbmessages = final.reverse()
            
            self.tableView.reloadData()
        }
        refreshControl.endRefreshing()
    }
    
    func reloadViewOnReopen(notification: NSNotification){
        let uniques = doesArrContainUnique(self.helperFunctions.loadCoreDataMessage(false)!, LoadedArr: self.crumbmessages, prevDropped: dropped)
        print("Loading in reload others")
        if uniques.isEmpty != true{//does this work?
            
            (final,dropped) = islimited(uniques, loaded: self.crumbmessages)
            self.crumbmessages = final
            
            
            self.tableView.reloadData()
        }
        //******************************************** Will want to reload votes *****************************************************
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return crumbmessages.count
    }
    
    //MARK: DELETE CRUMB
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            
            let id = crumbmessages[indexPath.row].uRecordID
            helperFunctions.coreDataDeleteCrumb(id!)
            
            crumbmessages.removeAtIndex(indexPath.row)
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if (self.tableView.editing) {
            return UITableViewCellEditingStyle.Delete
        }
        return UITableViewCellEditingStyle.None
    }
    
    //MARK: Delegation
    func updateVoteSpecific(NewVoteValue: Int, crumbUUID: String, hasVotedValue: Int){
        for crumbs in crumbmessages{
            if crumbs.uRecordID == crumbUUID{
                crumbs.hasVoted = hasVotedValue
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    crumbs.votes = NewVoteValue
                    self.tableView.reloadData()
                })
                break
            }
        }
    }
}
