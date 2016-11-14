//
//  ViewCrumbViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 4/22/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//
import UIKit
import MapKit
import CloudKit
import CoreData

class ViewCrumbViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CreateCommentDelegate, MKMapViewDelegate{
    
    //MARK: Variables
    var viewbreadcrumb: CrumbMessage?
    var comments = [CommentShort]()
    let helperFunctions = Helper()
    weak var delegate: NewOthersCrumbsViewControllerDelegate?
    
    @IBOutlet weak var YourtableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    
    //keeps track of votes in screen
    var counter = 0
    var hasVotedInScreen = false
    var theVoteValueToBeStored: Int = 0
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.YourtableView.delegate = self
        self.YourtableView.dataSource = self
                
        mapView.delegate = self

        mapView.subviews[1].hidden = true//not legal
        
        //anotations
        let mkAnnoTest = MKPointAnnotation.init()
        mkAnnoTest.coordinate = viewbreadcrumb!.location.coordinate
        mapView.addAnnotation(mkAnnoTest)
        mapView.camera.centerCoordinate = viewbreadcrumb!.location.coordinate
        mapView.camera.altitude = 1000
        
        YourtableView.rowHeight = UITableViewAutomaticDimension
        YourtableView.estimatedRowHeight = 50
        let now = NSDate()
        
        let new = CommentShort(username: "Don", text: "We won bigly and we will keep winning until you tire of winning!", timeSent: now)
        comments += [new]
    }
    
    /*func viewdidAppear(animated: Bool) {
        let attributionLabel = mapView.subviews[1]
        attributionLabel.frame = CGRectMake(8, 20, attributionLabel.frame.size.width, attributionLabel.frame.size.height);
    }*/
    override func viewWillDisappear(animated: Bool) {
        //send crumbvote here somehow
        if counter != 0 && hasVotedInScreen == true{
            print(theVoteValueToBeStored)
            crumbVote(theVoteValueToBeStored, counter: counter)
            if let del = self.delegate {
                del.updateVoteSpecific(theVoteValueToBeStored, crumbUUID: (viewbreadcrumb?.uRecordID)!, hasVotedValue: counter)
            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let num = comments.count + 1
        return num
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {        
        if indexPath.row == 0 {
            
            let msgCell = tableView.dequeueReusableCellWithIdentifier("YourMsgCell", forIndexPath: indexPath) as! CrumbTableViewCell
            
            msgCell.CreateCommentButton.addTarget(self, action: #selector(ViewCrumbViewController.commentSegue), forControlEvents: .TouchUpInside)
            
            msgCell.ExitCrumbButton.addTarget(self, action: #selector(ViewCrumbViewController.exitCrumb), forControlEvents: .TouchUpInside)
            
            //sets the values for the labels in the cell, time value and location value
            msgCell.MsgTextView.text = viewbreadcrumb!.text
            msgCell.UserLabel.text = viewbreadcrumb!.senderName
            msgCell.TimeLabel.text = "\(viewbreadcrumb!.dateOrganizer())"
            
            if viewbreadcrumb!.calculate() > 0 {
                let ref = Int(viewbreadcrumb!.calculate())
                
                if ref >= 1 {
                    msgCell.TimeLeftLabel.text! = "\(ref)h left"//////////////////////////////////////////////////
                }else {
                    msgCell.TimeLeftLabel.text = "Nearly Done!"
                }
            } else{
                msgCell.TimeLeftLabel.text! = "Time's up!"
            }

            
            msgCell.counter = counter
            msgCell.hasVotedInScreen = hasVotedInScreen
            msgCell.theVoteValueToBeStored = theVoteValueToBeStored
            //    cell.button.addTarget(self, action: "someAction", forControlEvents: .TouchUpInside)

            
            return msgCell
        }else {
            let commentCells = tableView.dequeueReusableCellWithIdentifier("commentYours", forIndexPath: indexPath) as! CommentCell
            
            let comment = comments[(indexPath.row - 1)]
            commentCells.CommentTextView.text = comment.text
            commentCells.usernameLabel.text = comment.username
            return commentCells
        }
    }
    // prepare view with object data;
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "writeComment") {
            let upcoming = segue.destinationViewController as! CreateCommentViewController
            upcoming.viewbreadcrumb = viewbreadcrumb
        }
        
    }
    

    
    func addNewComment(newComment: CommentShort){
        comments += [newComment]
        YourtableView.reloadData()
    }
    
    func crumbVote(vote: Int, counter: Int) {//what happens when a vote conflicts between cd and ck?, this just does ck atm
        let specificID = CKRecordID(recordName: (viewbreadcrumb?.uRecordID)!)
        voteCKVote(specificID)
        voteCoreDataVote((viewbreadcrumb?.uRecordID)!,counter: counter)
    }
    
    //redo these to only update a value not add
    func voteCKVote(recorduuid: CKRecordID){
        
        let container = CKContainer.defaultContainer()
        let publicData = container.publicCloudDatabase
        
        publicData.fetchRecordWithID(recorduuid, completionHandler: {record, error in
            if error == nil{
                let newvalue = self.theVoteValueToBeStored
                
                record!.setObject(newvalue, forKey: "votes")
                
                publicData.saveRecord(record!, completionHandler: {theRecord, error in
                    if error == nil{
                        print("saved version")
                    }else{
                        print(error)
                    }
                })
            }else{
                print(error)
            }
        })
    }
    
    //updates coredata with the new value
    func voteCoreDataVote(cdrecorduuid: String, counter: Int){
        
        let predicate = NSPredicate(format: "recorduuid == %@", cdrecorduuid)
        
        let fetchRequest = NSFetchRequest(entityName: "Message")
        fetchRequest.predicate = predicate
        
        do {// change it, it not work y?
            let fetchedMsgs = try helperFunctions.moc.executeFetchRequest(fetchRequest) as! [Message]
            
            fetchedMsgs.first?.setValue(theVoteValueToBeStored, forKey: "votevalue")
            fetchedMsgs.first?.setValue(counter, forKey: "hasVoted")
            do {// save it!
                try helperFunctions.moc.save()
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
        
    }
    func commentSegue(){
        performSegueWithIdentifier("writeComment", sender: self)
    }//        performSegueWithIdentifier("writeComment", sender: sender)

    func exitCrumb(){
        dismissViewControllerAnimated(true, completion: nil)
    }
}

/*protocol NewOthersCrumbsViewControllerDelegate: class {
 func updateVoteSpecific(NewVoteValue: Int, crumbUUID: String, hasVotedValue: Int)
 }*/
