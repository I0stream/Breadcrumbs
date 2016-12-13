//
//  ViewCrumbs.swift
//  scrollviewtest
//
//  Created by Daniel Schliesing on 10/27/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//
/*
import UIKit
import MapKit
import CloudKit
import CoreData

class ViewCrumbs: UIViewController, UITableViewDelegate, CreateCommentDelegate, MKMapViewDelegate {


    //MARK: Variables
    var viewbreadcrumb: CrumbMessage?
    var comments = [CommentShort]()
    let helperFunctions = Helper()
    weak var delegate: NewOthersCrumbsViewControllerDelegate?
    

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    
    //keeps track of votes in screen
    var counter = 0
    var hasVotedInScreen = false
    var theVoteValueToBeStored: Int = 0
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        //self.tableView.dataSource = self
        
        mapView.delegate = self

        //anotations
        let mkAnnoTest = MKPointAnnotation.init()
        mkAnnoTest.coordinate = viewbreadcrumb!.location.coordinate
        mapView.addAnnotation(mkAnnoTest)
        mapView.camera.centerCoordinate = viewbreadcrumb!.location.coordinate
        mapView.camera.altitude = 1000
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 95
        let now = Date()
        let new = CommentShort(username: "TrumpenFuhrer", text: "We won bigly and we will keep winning until you tire of winning!", timeSent: now)
        comments += [new]
    }
    override func viewWillDisappear(_ animated: Bool) {
        //send crumbvote here somehow
        if counter != 0 && hasVotedInScreen == true{
            print(theVoteValueToBeStored)
            crumbVote(theVoteValueToBeStored, counter: counter)
            if let del = self.delegate {
                del.updateVoteSpecific(theVoteValueToBeStored, crumbUUID: (viewbreadcrumb?.uRecordID)!, hasVotedValue: counter)
            }
        }
    }
    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let num = comments.count + 1
        return num
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "crumb", for: indexPath) as! CrumbTableViewCell
            //set the data here
            
            let crumbmsg = viewbreadcrumb
            
            // Fetches the appropriate msg for the data source layout.
            //sets the values for the labels in the cell, time value and location value
            cell.MsgTextView.text = crumbmsg!.text
            cell.UserLabel.text = crumbmsg!.senderName
            cell.TimeLabel.text = "\(viewbreadcrumb!.dateOrganizer())"
            
            cell.counter = counter
            cell.hasVotedInScreen = hasVotedInScreen
            cell.theVoteValueToBeStored = theVoteValueToBeStored
            
            return cell
        }else {
            print("cell")
            let cell = tableView.dequeueReusableCell(withIdentifier: "mycell", for: indexPath) as! CommentCell
            
            let comment = comments[(indexPath.row - 2)]
            cell.CommentTextView.text = comment.text
            cell.usernameLabel.text = comment.username
            return cell
        }
    }
    

    @IBAction func CreateCommentButton(_ sender: AnyObject) {
        performSegue(withIdentifier: "writeComment", sender: sender)
    }
    
    func addNewComment(_ newComment: CommentShort){
        comments += [newComment]
        tableView.reloadData()
    }


    
    func crumbVote(_ vote: Int, counter: Int) {//what happens when a vote conflicts between cd and ck?, this just does ck atm
        let specificID = CKRecordID(recordName: (viewbreadcrumb?.uRecordID)!)
        voteCKVote(specificID)
        voteCoreDataVote((viewbreadcrumb?.uRecordID)!,counter: counter)
    }
    
    //redo these to only update a value not add
    func voteCKVote(_ recorduuid: CKRecordID){
        
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        
        publicData.fetch(withRecordID: recorduuid, completionHandler: {record, error in
            if error == nil{
                let newvalue = self.theVoteValueToBeStored
                
                record!.setObject(newvalue as CKRecordValue?, forKey: "votes")
                
                publicData.save(record!, completionHandler: {theRecord, error in
                    if error == nil{
                        print("saved version")
                    }else{
                        print(error.debugDescription)
                    }
                })
            }else{
                print(error.debugDescription)
            }
        })
    }
    
    //updates coredata with the new value
    func voteCoreDataVote(_ cdrecorduuid: String, counter: Int){
        
        let predicate = NSPredicate(format: "recorduuid == %@", cdrecorduuid)
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Message")
        fetchRequest.predicate = predicate
        
        do {// change it, it not work y?
            let fetchedMsgs = try helperFunctions.moc.fetch(fetchRequest) as! [Message]
            
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
    

    
}

/*protocol NewOthersCrumbsViewControllerDelegate: class {
    func updateVoteSpecific(NewVoteValue: Int, crumbUUID: String, hasVotedValue: Int)
}*/
*/
