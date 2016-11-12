//
//  NewOthersCrumbsViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 4/29/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import UIKit
import CloudKit
import CoreData
import MapKit

class NewOthersCrumbsViewController: UIViewController, UITextViewDelegate, MKMapViewDelegate {


    //MARK: Properties
    @IBOutlet weak var mapViewOutlet: MKMapView!
    @IBOutlet weak var OtherMsgTextView: UITextView!
    @IBOutlet weak var OtherUserLabel: UILabel!
    @IBOutlet weak var TimeLabel: UILabel!
    @IBOutlet weak var updootColor: UIButton!
    @IBOutlet weak var downdootColor: UIButton!
    @IBOutlet weak var UpVoteValueLabel: UILabel!
    @IBOutlet weak var LocationLabel: UILabel!
    
    @IBOutlet weak var countdownLabel: UILabel!
    //MARK: Variables
    var viewbreadcrumb: CrumbMessage?
    let helperFunctions = Helper()
    var counter = 0
    var hasVotedInScreen = false
    var theVoteValueToBeStored: Int = 0
    var timer = NSTimer()
    weak var delegate: NewOthersCrumbsViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //init
        self.OtherMsgTextView.delegate = self
        self.mapViewOutlet.delegate = self
        self.mapViewOutlet.mapType = MKMapType.Standard
        
        
        //TextView border
        OtherMsgTextView.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).CGColor
        self.OtherMsgTextView.layer.borderWidth = 1.0;
        self.OtherMsgTextView.layer.cornerRadius = 5.0;
        
        //reset text justification to default
        self.automaticallyAdjustsScrollViewInsets = false
        
        //set up views for existing crumbs
        OtherMsgTextView.text = viewbreadcrumb?.text
        OtherUserLabel.text = viewbreadcrumb?.senderName
        TimeLabel.text = "\(viewbreadcrumb!.dateOrganizer())"
        UpVoteValueLabel.text = "\(String(viewbreadcrumb!.votes!))"
        
        /*if viewbreadcrumb?.addressStr != nil {
            LocationLabel.text = viewbreadcrumb?.addressStr
        }else{
             LocationLabel.text = "Address error"
        }*/
        
        //fix font size
        OtherMsgTextView.font = UIFont.systemFontOfSize(17)
        
        //autodefine textview size
        let fixedWidth = OtherMsgTextView.frame.size.width
        OtherMsgTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        let newSize = OtherMsgTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        var newFrame = OtherMsgTextView.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        OtherMsgTextView.frame = newFrame;
        
        //anotations
        let mkAnnoTest = MKPointAnnotation.init()
        mkAnnoTest.coordinate = viewbreadcrumb!.location.coordinate
        mapViewOutlet.addAnnotation(mkAnnoTest)
        mapViewOutlet.camera.centerCoordinate = viewbreadcrumb!.location.coordinate
        mapViewOutlet.camera.altitude = 1000
        
        
        if viewbreadcrumb?.hasVoted == 1{
            counter = 1
            updootColor.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
        }
        else if viewbreadcrumb?.hasVoted == -1{
            counter = -1
            downdootColor.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
        }
    }
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
    
    func crumbVote(vote: Int, counter: Int) {//what happens when a vote conflicts between cd and ck?, this just does ck atm
        let specificID = CKRecordID(recordName: (viewbreadcrumb?.uRecordID)!)
        voteCKVote(specificID)
        voteCoreDataVote((viewbreadcrumb?.uRecordID)!,counter: counter)
        
        dispatch_async(dispatch_get_main_queue()) {
            self.UpVoteValueLabel.text = "\(String(self.viewbreadcrumb!.votes!))"
        }
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
    //MARK: Comments
    
}
protocol NewOthersCrumbsViewControllerDelegate: class {
    func updateVoteSpecific(NewVoteValue: Int, crumbUUID: String, hasVotedValue: Int)
}
