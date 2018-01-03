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

class ViewCrumbViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CreateCommentDelegate, MKMapViewDelegate, reportreloaddelegate{
    
    //MARK: Variables
    var viewbreadcrumb: CrumbMessage?
    var comments = [CommentShort]()
    
    var conHeight: CGFloat?
    
    var segType: String?
    
    let userSelf = AppDelegate().NSUserData.string(forKey: "recordID")
    var votevalue = 0
    
    
    let helperFunctions = AppDelegate().helperfunctions
    //let helperFunctions = Helper()
    weak var delegate: NewOthersCrumbsViewControllerDelegate?
    let NSUserData = UserDefaults.standard
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ViewCrumbViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        
        return refreshControl
    }()
    
    
    //@IBOutlet weak var PALEBLUEDOT: UIImageView!
    
    @IBOutlet weak var YourtableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    //@IBOutlet weak var ButtonUIViewContainer: UIView!
    
    @IBOutlet weak var SaveCancelMenuView: UIView!
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
        
        //if refreshNeed == false {PALEBLUEDOT.isHidden = true}
        
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
        
        /*let cir:MKCircle = MKCircle(center: viewbreadcrumb!.location.coordinate, radius: CLLocationDistance(70)) //added this but nothing is displayed on map
        
        mapView.add(cir)*/

        
        YourtableView.rowHeight = UITableViewAutomaticDimension
        YourtableView.estimatedRowHeight = 200
        
        self.YourtableView.addSubview(self.refreshControl)
        
        
        //NotifLoad
        //NotificationCenter.default.addObserver(self, selector: #selector(ViewCrumbViewController.BlueDotIndicate(_:)),name:NSNotification.Name(rawValue: "NotifLoad"), object: nil)

        print(helperFunctions.CountComments(uniqueRecordID: (viewbreadcrumb?.uRecordID!)!)
)
        
        loadComments()
        //animateInfoBar("Pull to refresh")
        
        
    }
    
    /*func BlueDotIndicate(_ notification: Notification){
        if let recordid = notification.userInfo?["RecordUuid"] as? String{
            if recordid == self.viewbreadcrumb?.uRecordID{
                DispatchQueue.main.async(execute: { () -> Void in
                    self.PALEBLUEDOT.isHidden = false

                })
            }
        }
    }*/
    
    /*//http://stackoverflow.com/questions/32772498/how-to-add-a-circle-with-a-certain-radius-to-my-mkpointannotation-ios-swift
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let overlayRenderer : MKCircleRenderer = MKCircleRenderer(overlay: overlay);
        overlayRenderer.lineWidth = 1.0
        overlayRenderer.strokeColor = UIColor.red
        return overlayRenderer
    }*/
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let num = comments.count + 3// + because of invisible spacer plus the crumb being displayed plus second spacer
        return num
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {//spacer size
            
            if viewbreadcrumb?.photo == nil{
                let screenSize: CGRect = UIScreen.main.bounds
                let percentheight: CGFloat = screenSize.height * 0.5
                
                let height: CGFloat = percentheight - 50.0
                return height
            }else {
                let screenSize: CGRect = UIScreen.main.bounds
                let percentheight: CGFloat = screenSize.height * 0.5
                
                let height: CGFloat = percentheight - 125.0
                return height
            }
        }else if indexPath.row == comments.count + 2 || (comments.count == 0 && indexPath.row == indexPath.count){
            let screenSize: CGRect = UIScreen.main.bounds
            let percentheight: CGFloat = screenSize.height * 0.3
            
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
            
            if viewbreadcrumb?.photo == nil{//no photo
                let msgCell = tableView.dequeueReusableCell(withIdentifier: "YourMsgCell", for: indexPath) as! CrumbTableViewCell
                
                //report button
                
                if viewbreadcrumb?.senderuuid == userSelf{
                    msgCell.ReportButton.isHidden = true///////////////////////
                    msgCell.ReportButton.isEnabled = false
                }else if viewbreadcrumb?.senderuuid != userSelf{
                    msgCell.ReportButton.tag = indexPath.row
                    msgCell.ReportButton.addTarget(self, action: #selector(ViewCrumbViewController.report), for: .touchUpInside)
                }
                if viewbreadcrumb!.calculateTimeLeftInHours() > 0 {
                    msgCell.CreateCommentButton.addTarget(self, action: #selector(ViewCrumbViewController.commentSegue), for: .touchUpInside)
                    msgCell.VoteButton.addTarget(self, action: #selector(ViewCrumbViewController.Vote), for: .touchUpInside)
                    
                } else{
                    let color = UIColor(red: 146/255, green: 144/255, blue: 144/255, alpha: 1)//greay color
                    msgCell.CreateCommentButton.setTitleColor(color, for: .normal)
                    //msgCell.CreateCommentButton.addTarget(self, action: #selector(ViewCrumbViewController.noCommentIndicator), for: .touchUpInside)
                    //msgCell.VoteButton.addTarget(self, action: #selector(ViewCrumbViewController.noVoteIndicator), for: .touchUpInside)
                    
                }
                msgCell.ExitCrumbButton.addTarget(self, action: #selector(ViewCrumbViewController.exitCrumb), for: .touchUpInside)
                
                let normalColor = UIColor(red: 245/255, green: 166/255, blue: 35/255, alpha: 1)
                let bluecolor = UIColor(red: 64/255, green: 161/255, blue: 255/255, alpha: 1)
                
                //setColorVoteButton
                if viewbreadcrumb?.hasVoted == 1{//user has voted
                    msgCell.VoteButton.setTitleColor(bluecolor, for: .normal)
                    msgCell.VoteButton.setImage(#imageLiteral(resourceName: "likeHeartfilled"), for: .normal)
                    
                }else if viewbreadcrumb?.hasVoted == 0{
                    msgCell.VoteButton.setImage(#imageLiteral(resourceName: "likeHeartEmpty"), for: .normal)
                    msgCell.VoteButton.setTitleColor(normalColor, for: .normal)
                }
                
                //sets the values for the labels in the cell, time value and location value
                
                msgCell.VoteValue.text = "\(viewbreadcrumb!.votes)"
                
                
                msgCell.MsgTextView.text = viewbreadcrumb!.text
                msgCell.UserLabel.text = viewbreadcrumb!.senderName
                
                var textwidth = msgCell.UserLabel.intrinsicContentSize.width
                let contentwidth = UIScreen.main.bounds.width - 126//screen width minus total constraints and item widths + 15 padding
                if textwidth > contentwidth{
                    while textwidth > contentwidth {
                        msgCell.UserLabel.font = msgCell.UserLabel.font.withSize((msgCell.UserLabel.font.pointSize-1))
                        textwidth = msgCell.UserLabel.intrinsicContentSize.width
                    }
                }
                
                msgCell.TimeLabel.text = "\(viewbreadcrumb!.dateOrganizer())"
                if viewbreadcrumb!.calculateTimeLeftInHours() > 0 {
                    let ref = Int(viewbreadcrumb!.calculateTimeLeftInHours())
                    
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
            }else {//has photo
                //imagecrumbscell
                
                let msgCell = tableView.dequeueReusableCell(withIdentifier: "imagecrumbscell", for: indexPath) as! crumbPlusImageTableViewCell
                
                //report button
                
                
                msgCell.ImageViewOnCell.contentMode = .scaleAspectFill
                msgCell.ImageViewOnCell.image = viewbreadcrumb!.photo
                msgCell.imageButton.addTarget(self, action: #selector(ViewCrumbViewController.imageSeggy), for: .touchUpInside)
                
                let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressToSave(sender:)))
                longPressRecognizer.minimumPressDuration = 0.5
                msgCell.imageButton.addGestureRecognizer(longPressRecognizer)
                
                msgCell.ImageViewOnCell.layer.cornerRadius = 5.0
                msgCell.ImageViewOnCell.clipsToBounds = true
                
                

                
                if viewbreadcrumb?.senderuuid == userSelf{
                    msgCell.ReportButton.isHidden = true///////////////////////
                    msgCell.ReportButton.isEnabled = false
                }else if viewbreadcrumb?.senderuuid != userSelf{
                    msgCell.ReportButton.isHidden = false///////////////////////
                    msgCell.ReportButton.isEnabled = true

                    msgCell.ReportButton.tag = indexPath.row
                    msgCell.ReportButton.addTarget(self, action: #selector(ViewCrumbViewController.report), for: .touchUpInside)
                }
                if viewbreadcrumb!.calculateTimeLeftInHours() > 0 {
                    msgCell.CreateCommentButton.addTarget(self, action: #selector(ViewCrumbViewController.commentSegue), for: .touchUpInside)
                    msgCell.VoteButton.addTarget(self, action: #selector(ViewCrumbViewController.Vote), for: .touchUpInside)
                    
                } else{
                    let color = UIColor(red: 146/255, green: 144/255, blue: 144/255, alpha: 1)//greay color
                    msgCell.CreateCommentButton.setTitleColor(color, for: .normal)
                    //msgCell.CreateCommentButton.addTarget(self, action: #selector(ViewCrumbViewController.noCommentIndicator), for: .touchUpInside)
                    //msgCell.VoteButton.addTarget(self, action: #selector(ViewCrumbViewController.noVoteIndicator), for: .touchUpInside)
                    
                }
                msgCell.ExitCrumbButton.addTarget(self, action: #selector(ViewCrumbViewController.exitCrumb), for: .touchUpInside)
                
                let normalColor = UIColor(red: 245/255, green: 166/255, blue: 35/255, alpha: 1)
                let bluecolor = UIColor(red: 64/255, green: 161/255, blue: 255/255, alpha: 1)
                
                //setColorVoteButton
                if viewbreadcrumb?.hasVoted == 1{//user has voted
                    msgCell.VoteButton.setTitleColor(bluecolor, for: .normal)
                    msgCell.VoteButton.setImage(#imageLiteral(resourceName: "likeHeartfilled"), for: .normal)
                    
                }else if viewbreadcrumb?.hasVoted == 0{
                    msgCell.VoteButton.setImage(#imageLiteral(resourceName: "likeHeartEmpty"), for: .normal)
                    msgCell.VoteButton.setTitleColor(normalColor, for: .normal)
                }
                
                //sets the values for the labels in the cell, time value and location value
                
                msgCell.VoteValue.text = "\(viewbreadcrumb!.votes)"
                
                
                msgCell.MsgTextView.text = viewbreadcrumb!.text
                msgCell.UserLabel.text = viewbreadcrumb!.senderName
                
                var textwidth = msgCell.UserLabel.intrinsicContentSize.width
                let contentwidth = UIScreen.main.bounds.width - 126//screen width minus total constraints and item widths + 15 padding
                if textwidth > contentwidth{
                    while textwidth > contentwidth {
                        msgCell.UserLabel.font = msgCell.UserLabel.font.withSize((msgCell.UserLabel.font.pointSize-1))
                        textwidth = msgCell.UserLabel.intrinsicContentSize.width
                    }
                }
                
                msgCell.TimeLabel.text = "\(viewbreadcrumb!.dateOrganizer())"
                if viewbreadcrumb!.calculateTimeLeftInHours() > 0 {
                    let ref = Int(viewbreadcrumb!.calculateTimeLeftInHours())
                    
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

            }
            
            
            // indexPath.row == indexPath.last
        }else if indexPath.row == comments.count + 2 || (comments.count == 0 && indexPath.row == indexPath.count) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Spacer", for: indexPath)
            cell.selectionStyle = .none
            
            return cell
        }else{
            let commentCells = tableView.dequeueReusableCell(withIdentifier: "commentYours", for: indexPath) as! CommentCell
            commentCells.selectionStyle = .none
            
            //print("index",indexPath.row)
            
            let comment = comments[(indexPath.row - 2)]
            commentCells.CommentTextView.text = comment.text
            
            commentCells.usernameLabel.text = comment.username
            
            var textwidth = commentCells.usernameLabel.intrinsicContentSize.width
            let contentwidth = UIScreen.main.bounds.width - 210//screen width minus total constraints and item widths + 15 padding
            if textwidth > contentwidth{
                while textwidth > contentwidth {
                    commentCells.usernameLabel.font = commentCells.usernameLabel.font.withSize((commentCells.usernameLabel.font.pointSize-1))
                    textwidth = commentCells.usernameLabel.intrinsicContentSize.width
                }
            }
            
            
            
            commentCells.timeAgoLabel.text = comment.timeRelative()//time is how long ago it was posted, dont see the point to change var name to something more explanatory right now
            
            if comment.userID == userSelf{
                commentCells.ReportButton.isHidden = true
                commentCells.ReportButton.isEnabled = false
            }else if comment.userID != userSelf{
                commentCells.ReportButton.tag = (indexPath.row)
                commentCells.ReportButton.addTarget(self, action: #selector(ViewCrumbViewController.report), for: .touchUpInside)
            }
            
            return commentCells
        }
        
    }
    
    func imageSeggy(sender: UIButton){
        print("segue to image viewer")
        self.performSegue(withIdentifier: "viewimageviewseg", sender: sender)
        
    }
    //MARK: REport
    
    func report(sender: UIButton) {
        if viewbreadcrumb!.calculateTimeLeftInHours() > 0 {
            performSegue(withIdentifier: "ReportMenuSegue", sender: sender)
            
        }else{
            let alertController = UIAlertController(title: "BreadCrumbs", message:
                "You cannot report a dead crumb as it has been deleted", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        }

    }
    
    
    
    
    //MARK: Commenting functions
    
    // prepare view with object data;
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "writeComment") && viewbreadcrumb!.calculateTimeLeftInHours() > 0 {
            let upcoming = segue.destination as! CreateCommentViewController
            upcoming.viewbreadcrumb = viewbreadcrumb
            let destVC = segue.destination as! CreateCommentViewController
            destVC.delegate = self
        } else if (segue.identifier == "ReportMenuSegue") && viewbreadcrumb!.calculateTimeLeftInHours() > 0{
        
            let upcoming = segue.destination as! ReportMenuViewController
            upcoming.delegate = self
            
            let button = sender as! UIButton
            let tag = button.tag
            if tag == 1{
                upcoming.reportedMessageId = viewbreadcrumb?.uRecordID
                upcoming.reportedUserId = viewbreadcrumb?.senderuuid
                upcoming.reportedtext = viewbreadcrumb?.text
                upcoming.reporteduserID = viewbreadcrumb?.senderuuid
                upcoming.typeToReport = "crumbmessage"
                
                if viewbreadcrumb?.photo != nil{
                    upcoming.reportedPhoto = viewbreadcrumb?.photo!
                }
                
            }else{
                let index = tag - 2
                let comment = comments[index]
                upcoming.reportedMessageId = comment.recorduuid
                upcoming.reportedUserId = comment.userID
                upcoming.reportedtext = comment.text
                upcoming.reporteduserID = comment.userID
                upcoming.typeToReport = "comment"
            }
        } else if segue.identifier == "viewimageviewseg"{
            let upcoming = segue.destination as!ImageViewerViewController
            upcoming.theImage = viewbreadcrumb?.photo
            
        }
    }
    
    
    //createcommentdelegate function
    func addNewComment(_ newComment: CommentShort){
        print("new comment")
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
            //saves voting stuff
            helperFunctions.crumbVote((viewbreadcrumb?.hasVoted!)!, crumb: viewbreadcrumb!, voteValue: votevalue )
            delegate?.reloadTables()
        }
        //
        dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: Refresh
    
    
   /* @IBAction func RefreshButtonAction(_ sender: Any) {
        
        reloadForRefresh()

        let button = (sender as! UIButton)
        
        UIView.animate(withDuration: 0.5, animations:{
            button.transform = button.transform.rotated(by: CGFloat.pi)
            button.transform = button.transform.rotated(by: CGFloat.pi)
        })
        
    }*/
    
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        reloadForRefresh()
        refreshControl.endRefreshing()
    }
    
    
    func reloadForRefresh(){
        
        DispatchQueue.main.async(execute: { () -> Void in
            
            if self.refreshNeed{//if we know there is a msg in cd use only cd
                //button go away (blue dot)
                
                //self.PALEBLUEDOT.isHidden = true
                self.refreshNeed = false
                //also update crumb
                self.viewbreadcrumb = self.helperFunctions.getSpecific(recorduuid: (self.viewbreadcrumb?.uRecordID)!)
            }else {//if user wants to refresh constantly, use both
                //button go away (blue dot)
                
                //self.PALEBLUEDOT.isHidden = true
                self.refreshNeed = false
                //also update crumb
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
            votevalue = -1
            viewbreadcrumb?.votes = (viewbreadcrumb?.votes)! - 1
            
        }else if viewbreadcrumb?.hasVoted == 0 && inscreen == false{//has not voted before +1
            inscreen = true
            viewbreadcrumb?.hasVoted = 1
            votevalue = 1
            viewbreadcrumb?.votes
                = (viewbreadcrumb?.votes)! + 1
        } else if viewbreadcrumb?.hasVoted == 1 && inscreen == true{
            viewbreadcrumb?.hasVoted = 0
            votevalue = -1
            viewbreadcrumb?.votes = (viewbreadcrumb?.votes)! - 1
            
        }else if viewbreadcrumb?.hasVoted == 0 && inscreen == true{
            viewbreadcrumb?.hasVoted = 1
            votevalue = 1
            viewbreadcrumb?.votes
                = (viewbreadcrumb?.votes)! + 1
        }
        if viewbreadcrumb?.hasVoted == 1{//resets color
            let bluecolor = UIColor(red: 64/255, green: 161/255, blue: 255/255, alpha: 1)
            msgCell.VoteButton.setTitleColor(bluecolor, for: .normal)
        }else if viewbreadcrumb?.hasVoted == 0{
            let normalColor = UIColor(red: 245/255, green: 166/255, blue: 35/255, alpha: 1)
            msgCell.VoteButton.setTitleColor(normalColor, for: .normal)
        }
        
  //      //saves voting stuff
//        helperFunctions.crumbVote((viewbreadcrumb?.hasVoted!)!, crumb: viewbreadcrumb!, voteValue: votevalue )
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
    
    func reload() {
        segType = "comment"
        self.comments.removeAll()
        self.loadComments()//cd
        
        self.YourtableView.reloadData()
    }
    
    
    /*@IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
    }
    override func canPerformUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any) -> Bool {
        return true
    }*/


    
    @IBAction func savefotoButtonAction(_ sender: Any) {
        saveimagePopUp()
        SaveCancelMenuView.isHidden = true
    }
    
    
    @IBAction func cancelsave(_ sender: Any) {
        SaveCancelMenuView.isHidden = true

    }

    
    //press to save functions
    func longPressToSave(sender: UILongPressGestureRecognizer) {
        //use popover revopop\\\poppy im poppy popover///\\\(((Rootless cosmopolitans)))
        SaveCancelMenuView.isHidden = false
    }
    
    func saveimagePopUp(){
        UIImageWriteToSavedPhotosAlbum((viewbreadcrumb?.photo)!, self, #selector(image(image:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    func image(image: UIImage!, didFinishSavingWithError error: NSError!, contextInfo: AnyObject!) {
        if (error != nil) {
            print(error)
            
        } else {
            print("alright")
        }
    }
    
}
//reloads table in yours or others in order to persist vote button colors colors
protocol NewOthersCrumbsViewControllerDelegate: class {
    func reloadTables()
}

