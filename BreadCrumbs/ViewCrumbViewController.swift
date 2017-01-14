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
    
    var conHeight: CGFloat?
    
    let helperFunctions = AppDelegate().helperfunctions
    //let helperFunctions = Helper()
    weak var delegate: NewOthersCrumbsViewControllerDelegate?
    let NSUserData = UserDefaults.standard
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ViewCrumbViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        
        return refreshControl
    }()
    
    
    @IBOutlet weak var PALEBLUEDOT: UIImageView!
    
    @IBOutlet weak var YourtableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var ButtonUIViewContainer: UIView!
    
    //keeps track of votes in screen
    var inscreen = false
    
    //tracks cell heights
    var crumbHeight: CGFloat?
    
    //tracks need to refresh
    var refreshNeed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if conHeight == nil{
            conHeight = 49 + 20
        }
        
        for subview in view.subviews as [UIView] {
            for constraint in subview.constraints as [NSLayoutConstraint] {
                if constraint.identifier == "BottomLayoutFloat" {
                    constraint.constant = conHeight!
                }
            }
        }
        
        
        if viewbreadcrumb?.hasVoted == nil { viewbreadcrumb?.hasVoted = 0}
        
        if refreshNeed == false {PALEBLUEDOT.isHidden = true}
        
        self.YourtableView.delegate = self
        self.YourtableView.dataSource = self
                
        mapView.delegate = self

        //mapView.subviews[1].isHidden = true//not legal
        
        //anotations
        let mkAnnoTest = MKPointAnnotation.init()
        mkAnnoTest.coordinate = viewbreadcrumb!.location.coordinate
        mapView.addAnnotation(mkAnnoTest)
        mapView.camera.centerCoordinate = viewbreadcrumb!.location.coordinate
        mapView.camera.altitude = 1000
        
        YourtableView.rowHeight = UITableViewAutomaticDimension
        YourtableView.estimatedRowHeight = 200
        
        self.YourtableView.addSubview(self.refreshControl)
        
        
        //NotifLoad
        NotificationCenter.default.addObserver(self, selector: #selector(ViewCrumbViewController.BlueDotIndicate(_:)),name:NSNotification.Name(rawValue: "NotifLoad"), object: nil)

        loadComments()
        //animateInfoBar("Pull to refresh")
    }
    
    func BlueDotIndicate(_ notification: Notification){
        if let recordid = notification.userInfo?["RecordID"] as? String{
            if recordid == self.viewbreadcrumb?.uRecordID{
                DispatchQueue.main.async(execute: { () -> Void in
                    self.PALEBLUEDOT.isHidden = false

                })
            }
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let num = comments.count + 2// + because of invisible spacer plus the crumb being displayed plus refresher
        return num
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {//spacer size
            let screenSize: CGRect = UIScreen.main.bounds
            let percentheight: CGFloat = screenSize.height * 0.5
            
            let height: CGFloat = percentheight - 50.0
            return height
        }else if indexPath.row == 1{//crumb size
            if crumbHeight != nil{
                return crumbHeight!
            }else {
                crumbHeight = YourtableView.rowHeight
                return YourtableView.rowHeight
            }
        }else{//comment size or whatever
            return YourtableView.rowHeight
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0{
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "Spacer", for: indexPath)
            cell.selectionStyle = .none
            
            return cell
        }else if indexPath.row == 1 {
            let msgCell = tableView.dequeueReusableCell(withIdentifier: "YourMsgCell", for: indexPath) as! CrumbTableViewCell
            
            if viewbreadcrumb!.calculate() > 0 {
                msgCell.CreateCommentButton.addTarget(self, action: #selector(ViewCrumbViewController.commentSegue), for: .touchUpInside)
                msgCell.VoteButton.addTarget(self, action: #selector(ViewCrumbViewController.Vote), for: .touchUpInside)
                
            } else{
                let color = UIColor(red: 146/255, green: 144/255, blue: 144/255, alpha: 1)//greay color
                msgCell.CreateCommentButton.setTitleColor(color, for: .normal)
                msgCell.CreateCommentButton.addTarget(self, action: #selector(ViewCrumbViewController.noCommentIndicator), for: .touchUpInside)
                msgCell.VoteButton.addTarget(self, action: #selector(ViewCrumbViewController.noVoteIndicator), for: .touchUpInside)
                
            }
            msgCell.ExitCrumbButton.addTarget(self, action: #selector(ViewCrumbViewController.exitCrumb), for: .touchUpInside)
            
            
            //sets the values for the labels in the cell, time value and location value
            if viewbreadcrumb?.votes != 1{
                msgCell.VoteValueLabel.text = "\((viewbreadcrumb?.votes)!) votes"
            } else {
                msgCell.VoteValueLabel.text = "\((viewbreadcrumb?.votes)!) vote"
            }
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
                
                //Time's up indication Red Color
                let uicolor = UIColor(red: 225/255, green: 50/255, blue: 50/255, alpha: 1)
                msgCell.TimeLeftLabel.textColor = uicolor
                //
            }
            
            
            //setColorVoteButton
            if viewbreadcrumb?.hasVoted == 1{//user has voted
                let bluecolor = UIColor(red: 64/255, green: 161/255, blue: 255/255, alpha: 1)
                msgCell.VoteButton.setTitleColor(bluecolor, for: .normal)
            }else if viewbreadcrumb?.hasVoted == 0{
                let normalColor = UIColor(red: 245/255, green: 166/255, blue: 35/255, alpha: 1)
                msgCell.VoteButton.setTitleColor(normalColor, for: .normal)
            }
            return msgCell
        }else {
            let commentCells = tableView.dequeueReusableCell(withIdentifier: "commentYours", for: indexPath) as! CommentCell
            commentCells.selectionStyle = .none
            
            let comment = comments[(indexPath.row - 2)]
            commentCells.CommentTextView.text = comment.text
            commentCells.usernameLabel.text = comment.username
            commentCells.timeAgoLabel.text = comment.timeRelative()//time is how long ago it was posted, dont see the point to change var name to something more explanatory right now
            
            return commentCells
        }
        
        //if last add "SpacerBottom"?
    }
    
    //MARK: Commenting functions
    
    // prepare view with object data;
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "writeComment") && viewbreadcrumb!.calculate() > 0 {
            let upcoming = segue.destination as! CreateCommentViewController
            upcoming.viewbreadcrumb = viewbreadcrumb
            let destVC = segue.destination as! CreateCommentViewController
            destVC.delegate = self

        }
    }
    
    
    //createcommentdelegate function
    func addNewComment(_ newComment: CommentShort){
        comments += [newComment]
        YourtableView.reloadData()
    }
    
    
    func loadComments(){
        let fmcom = helperFunctions.loadComments(uniqueRecordID: (viewbreadcrumb?.uRecordID!)!)
        
        let sortedCom = fmcom.sorted(by: {$0.timeSent.timeIntervalSince1970 < $1.timeSent.timeIntervalSince1970})

        
            //sort comments by date here
        comments.append(contentsOf: sortedCom)
    }
    
    func commentSegue(){
        performSegue(withIdentifier: "writeComment", sender: self)
    }//        performSegueWithIdentifier("writeComment", sender: sender)

    func exitCrumb(){
        if inscreen == true{
            delegate?.reloadTables()
        }
        //
        dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: Refresh
    
    
    @IBAction func RefreshButtonAction(_ sender: Any) {
        
        reloadForRefresh()

        let button = (sender as! UIButton)
        
        UIView.animate(withDuration: 0.5, animations:{
            button.transform = button.transform.rotated(by: CGFloat.pi)
            button.transform = button.transform.rotated(by: CGFloat.pi)
        })
        
    }
    
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        reloadForRefresh()
        refreshControl.endRefreshing()
    }
    
    
    func reloadForRefresh(){
        
        DispatchQueue.main.async(execute: { () -> Void in
            
            if self.refreshNeed{//if we know there is a msg in cd use only cd
                print("away blue dot")
                //button go away (blue dot)
                
                self.PALEBLUEDOT.isHidden = true
                self.refreshNeed = false
                //also update crumb
                self.viewbreadcrumb = self.helperFunctions.getSpecific(recorduuid: (self.viewbreadcrumb?.uRecordID)!)
            }else {//if user wants to refresh constantly, use both
                //ck
                self.helperFunctions.getcommentcktocd(ckidToTest: CKRecordID(recordName: (self.viewbreadcrumb?.uRecordID)!))
                self.viewbreadcrumb = self.helperFunctions.getSpecific(recorduuid: (self.viewbreadcrumb?.uRecordID)!)
            }
            self.comments.removeAll()
            self.loadComments()//cd
            
            self.YourtableView.reloadData()
        })
    }
    
    //MARK: Voting
    //Voting is now simply handled by one button
    //therefore it can only vote and unvote(no negative votes)
    //given that this is the same across the whole app; in view, others, and yours
    //and they all use selectors, I can locate all the saving ck, cd, updating etc in helperfunctions
    //i just need to do it in a way that disallows double voting and ensures proper saving/updating
    
    func Vote(){
        let indexPath = IndexPath(row: 1, section: 1)
        let msgCell = YourtableView.dequeueReusableCell(withIdentifier: "YourMsgCell", for: indexPath) as! CrumbTableViewCell
        
        //voting
        //sets a couple values according to past versions of thos values
        if viewbreadcrumb?.hasVoted == 1 && inscreen == false{//has voted before setting vote to zero this is bad because of past structure
            inscreen = true
            viewbreadcrumb?.hasVoted = 0
            viewbreadcrumb?.votes! = (viewbreadcrumb?.votes)! - 1
            
        }else if viewbreadcrumb?.hasVoted == 0 && inscreen == false{//has not voted before +1
            inscreen = true
            viewbreadcrumb?.hasVoted = 1
            viewbreadcrumb?.votes!
                = (viewbreadcrumb?.votes)! + 1
        } else if viewbreadcrumb?.hasVoted == 1 && inscreen == true{
            viewbreadcrumb?.hasVoted = 0
            viewbreadcrumb?.votes! = (viewbreadcrumb?.votes)! - 1
            
        }else if viewbreadcrumb?.hasVoted == 0 && inscreen == true{
            viewbreadcrumb?.hasVoted = 1
            viewbreadcrumb?.votes!
                = (viewbreadcrumb?.votes)! + 1
        }
        if viewbreadcrumb?.hasVoted == 1{//resets color
            let bluecolor = UIColor(red: 64/255, green: 161/255, blue: 255/255, alpha: 1)
            msgCell.VoteButton.setTitleColor(bluecolor, for: .normal)
        }else if viewbreadcrumb?.hasVoted == 0{
            let normalColor = UIColor(red: 245/255, green: 166/255, blue: 35/255, alpha: 1)
            msgCell.VoteButton.setTitleColor(normalColor, for: .normal)
        }
        
        //saves voting stuff
        helperFunctions.crumbVote((viewbreadcrumb?.hasVoted!)!, crumb: viewbreadcrumb! )
        //update table
        DispatchQueue.main.async(execute: { () -> Void in
            self.YourtableView.reloadData()
        })
    }
    
    //MARK: Alert disabled
    func noCommentIndicator(){
        let alertController = UIAlertController(title: "BreadCrumbs", message:
            "You cannot comment on a dead crumb", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func noVoteIndicator(){
        let alertController = UIAlertController(title: "BreadCrumbs", message:
            "You cannot vote on a dead crumb", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
}
//reloads table in yours or others in order to persist vote button colors colors
protocol NewOthersCrumbsViewControllerDelegate: class {
    func reloadTables()
}

