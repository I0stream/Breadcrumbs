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
    var crumbmsg: CrumbMessage!
    var comments = [CommentShort]()
    
    var conHeight: CGFloat?
    
    var segType: String?
    
    let userSelf = AppDelegate().NSUserData.string(forKey: "recordID")
    var votevalue = 0
    
    let orangeColor = UIColor(red: 245/255, green: 166/255, blue: 35/255, alpha: 1)
    let blueColor = UIColor(red: 64/255, green: 161/255, blue: 255/255, alpha: 1)
    let greyColor = UIColor(red: 146/255, green: 144/255, blue: 144/255, alpha: 1)
    
    let helperFunctions = AppDelegate().helperfunctions
    //let helperFunctions = Helper()
    weak var delegate: NewOthersCrumbsViewControllerDelegate?
    let NSUserData = UserDefaults.standard
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ViewCrumbViewController.handleRefresh(_:)), for: UIControl.Event.valueChanged)
        
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
        
        
        if crumbmsg?.hasVoted == nil { crumbmsg?.hasVoted = 0}
        
        //if refreshNeed == false {PALEBLUEDOT.isHidden = true}
        
        self.YourtableView.delegate = self
        self.YourtableView.dataSource = self
                
        mapView.delegate = self

        //mapView.subviews[1].isHidden = true//not legal
        
        //anotations
        let mkAnnoTest = MKPointAnnotation.init()
        mkAnnoTest.coordinate = crumbmsg!.location.coordinate
        mapView.addAnnotation(mkAnnoTest)
        mapView.camera.centerCoordinate = crumbmsg!.location.coordinate
        mapView.camera.altitude = 1000
        
        /*let cir:MKCircle = MKCircle(center: viewbreadcrumb!.location.coordinate, radius: CLLocationDistance(70)) //added this but nothing is displayed on map
        
        mapView.add(cir)*/

        
        YourtableView.rowHeight = UITableView.automaticDimension
        YourtableView.estimatedRowHeight = 200
        
        self.YourtableView.addSubview(self.refreshControl)
        
        
        //NotifLoad
        //NotificationCenter.default.addObserver(self, selector: #selector(ViewCrumbViewController.BlueDotIndicate(_:)),name:NSNotification.Name(rawValue: "NotifLoad"), object: nil)

        //print(helperFunctions.CountComments(uniqueRecordID: (crumbmsg?.uRecordID!)!))
        
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
            
            if crumbmsg?.photo == nil{
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
            
            if crumbmsg?.photo == nil{//no photo
                let cell = tableView.dequeueReusableCell(withIdentifier: "YourMsgCell", for: indexPath) as! CrumbTableViewCell
                
                
                cell.ExitCrumbButton.addTarget(self, action: #selector(ViewCrumbViewController.exitCrumb), for: .touchUpInside)
                //report button
                
                if crumbmsg?.senderuuid == userSelf{
                    cell.ReportButton.isHidden = true///////////////////////
                    cell.ReportButton.isEnabled = false
                }else if crumbmsg?.senderuuid != userSelf{
                    cell.ReportButton.tag = indexPath.row
                    cell.ReportButton.addTarget(self, action: #selector(ViewCrumbViewController.report), for: .touchUpInside)
                }
                
                if crumbmsg!.calculateTimeLeftInHours() > 0 {
                    cell.CommentButton.addTarget(self, action: #selector(ViewCrumbViewController.commentSegue), for: .touchUpInside)
                    cell.VoteButton.addTarget(self, action: #selector(ViewCrumbViewController.Vote), for: .touchUpInside)
                    
                } else{
                    let color = UIColor(red: 146/255, green: 144/255, blue: 144/255, alpha: 1)//greay color
                    cell.CommentButton.setTitleColor(color, for: .normal)
                    //msgCell.CreateCommentButton.addTarget(self, action: #selector(ViewCrumbViewController.noCommentIndicator), for: .touchUpInside)
                    //msgCell.VoteButton.addTarget(self, action: #selector(ViewCrumbViewController.noVoteIndicator), for: .touchUpInside)
                    
                }
                
                //setColorVoteButton
                if crumbmsg!.isAlive(){
                    cell.CommentButton.setImage(#imageLiteral(resourceName: "comment"), for: .normal)
                    cell.CommentValueLabel.textColor = orangeColor
                } else{
                    cell.CommentButton.setImage(#imageLiteral(resourceName: "Comment-Grey"), for: .normal)
                    cell.CommentValueLabel.textColor = greyColor
                }
                
                
                

                
                //setColorVoteButton and value color
                if crumbmsg.hasVoted == 1{//user has voted
                    if crumbmsg.isAlive(){
                        cell.VoteButton.setImage(#imageLiteral(resourceName: "likeHeartfilled"), for: .normal)
                        cell.VoteValue.textColor = orangeColor
                    } else{
                        cell.VoteButton.setImage(#imageLiteral(resourceName: "likeHeartFilled-Grey"), for: .normal)
                        cell.VoteValue.textColor = greyColor
                    }
                    
                }else if crumbmsg.hasVoted == 0{
                    if crumbmsg.isAlive(){
                        cell.VoteButton.setImage(#imageLiteral(resourceName: "likeHeartEmpty"), for: .normal)
                        cell.VoteValue.textColor = orangeColor
                    } else{ //dead
                        cell.VoteButton.setImage(#imageLiteral(resourceName: "likeHearEmpty-Grey"), for: .normal)
                        cell.VoteValue.textColor = greyColor
                    }
                }

                
                //sets the values for the labels in the cell, time value and location value
                
                cell.VoteValue.text = "\(crumbmsg!.votes)"
                cell.CommentValueLabel.text = "\(comments.count)"
                
                cell.MsgTextView.text = crumbmsg!.text
                cell.UserLabel.text = crumbmsg!.senderName
                
                var textwidth = cell.UserLabel.intrinsicContentSize.width
                let contentwidth = UIScreen.main.bounds.width - 126//screen width minus total constraints and item widths + 15 padding
                if textwidth > contentwidth{
                    while textwidth > contentwidth {
                        cell.UserLabel.font = cell.UserLabel.font.withSize((cell.UserLabel.font.pointSize-1))
                        textwidth = cell.UserLabel.intrinsicContentSize.width
                    }
                }
                
                cell.TimeLabel.text = "\(crumbmsg!.dateOrganizer())"
                if crumbmsg!.calculateTimeLeftInHours() > 0 {
                    let ref = Int(crumbmsg!.calculateTimeLeftInHours())
                    
                    if ref >= 1 {
                        cell.TimeLeftLabel.text! = "\(ref)h left"//////////////////////////////////////////////////
                    }else {
                        cell.TimeLeftLabel.text = "Nearly Done!"
                    }
                } else{
                    cell.TimeLeftLabel.text! = "Time's up!"
                    
                    //Time's up indication Red Color
                    let uicolor = UIColor(red: 225/255, green: 50/255, blue: 50/255, alpha: 1)
                    cell.TimeLeftLabel.textColor = uicolor
                    //
                }
                
                
                //setColorVoteButton
                if crumbmsg?.hasVoted == 1{//user has voted
                    cell.VoteButton.setTitleColor(blueColor, for: .normal)
                }else if crumbmsg?.hasVoted == 0{
                    cell.VoteButton.setTitleColor(orangeColor, for: .normal)
                }
                return cell
            }else if crumbmsg.text == "   " || crumbmsg.text == ""{//MARK: CopyPasta code from yours and others, FML reWriting PHOTO ONLY
                
                
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "OnlyPhotoCell", for: indexPath) as! PhotoOnlyTableViewCell
                
                //Hide report button if you are the owner if not enable it
                if crumbmsg?.senderuuid == userSelf{
                    cell.ReportButton.isHidden = true///////////////////////
                    cell.ReportButton.isEnabled = false
                }else if crumbmsg?.senderuuid != userSelf{
                    cell.ReportButton.isHidden = false///////////////////////
                    cell.ReportButton.isEnabled = true
                    
                    cell.ReportButton.tag = indexPath.row
                    cell.ReportButton.addTarget(self, action: #selector(ViewCrumbViewController.report), for: .touchUpInside)
                }
                
                
                //.scaleAspectFit
                cell.UserUploadedPhotoUIView.contentMode = .scaleAspectFill
                cell.UserUploadedPhotoUIView.image = crumbmsg.photo
                
                /*if original aspect ratio is non landscape position the photo as wide and focused on the top*/
                
                cell.imageButton.addTarget(self, action: #selector(ViewCrumbViewController.imageSeggy), for: .touchUpInside)
                
                cell.ExitCrumbButton.addTarget(self, action: #selector(ViewCrumbViewController.exitCrumb), for: .touchUpInside)
                cell.ExitCrumbButton.isUserInteractionEnabled = true

                let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressToSave(sender:)))
                longPressRecognizer.minimumPressDuration = 0.5
                cell.imageButton.addGestureRecognizer(longPressRecognizer)
                
                cell.imageButton.tag = indexPath.row
                cell.imageButton.addTarget(self, action: #selector(YourCrumbsTableViewController.imageSeggy), for: .touchUpInside)
                
                cell.UserUploadedPhotoUIView.layer.cornerRadius = 5.0
                cell.UserUploadedPhotoUIView.clipsToBounds = true
                
                
                //sets the values for the labels in the cell, time value and location value
                
                //setColorVoteButton
                if crumbmsg.isAlive(){
                    cell.CommentButton.setImage(#imageLiteral(resourceName: "comment"), for: .normal)
                    cell.CommentValueLabel.textColor = orangeColor
                } else{
                    cell.CommentButton.setImage(#imageLiteral(resourceName: "Comment-Grey"), for: .normal)
                    cell.CommentValueLabel.textColor = greyColor
                }
                
                //setColorVoteButton and value color
                if crumbmsg.hasVoted == 1{//user has voted
                    if crumbmsg.isAlive(){
                        cell.VoteButton.setImage(#imageLiteral(resourceName: "likeHeartfilled"), for: .normal)
                        cell.VoteValue.textColor = orangeColor
                    } else{
                        cell.VoteButton.setImage(#imageLiteral(resourceName: "likeHeartFilled-Grey"), for: .normal)
                        cell.VoteValue.textColor = greyColor
                    }
                    
                }else if crumbmsg.hasVoted == 0{
                    if crumbmsg.isAlive(){
                        cell.VoteButton.setImage(#imageLiteral(resourceName: "likeHeartEmpty"), for: .normal)
                        cell.VoteValue.textColor = orangeColor
                    } else{ //dead
                        cell.VoteButton.setImage(#imageLiteral(resourceName: "likeHearEmpty-Grey"), for: .normal)
                        cell.VoteValue.textColor = greyColor
                    }
                }
                
                
                //sets the values for the labels in the cell, time value and location value
                
                cell.CommentValueLabel.text = "\(comments.count)"
                //set action for create comment button
                if crumbmsg!.calculateTimeLeftInHours() > 0 {
                    cell.CommentButton.addTarget(self, action: #selector(ViewCrumbViewController.commentSegue), for: .touchUpInside)
                    cell.VoteButton.addTarget(self, action: #selector(ViewCrumbViewController.Vote), for: .touchUpInside)
                    
                } else{
                    let color = UIColor(red: 146/255, green: 144/255, blue: 144/255, alpha: 1)//greay color
                    cell.CommentButton.setTitleColor(color, for: .normal)
                    //msgCell.CreateCommentButton.addTarget(self, action: #selector(ViewCrumbViewController.noCommentIndicator), for: .touchUpInside)
                    //msgCell.VoteButton.addTarget(self, action: #selector(ViewCrumbViewController.noVoteIndicator), for: .touchUpInside)
                    
                }
                
                
                cell.VoteValue.text = "\(crumbmsg!.votes)"
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
                
                
                if crumbmsg.calculateTimeLeftInHours() > 0 {
                    let ref = Int(crumbmsg.calculateTimeLeftInHours())
                    
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
                
                //setColorVoteButton
                if crumbmsg?.hasVoted == 1{//user has voted
                    cell.VoteButton.setTitleColor(blueColor, for: .normal)
                }else if crumbmsg?.hasVoted == 0{
                    cell.VoteButton.setTitleColor(orangeColor, for: .normal)
                }
                
                ///setup to resize aspect ratio
                let heightConstraint = cell.PhotoHeightConstraint.constant
                let widthConstraint = cell.PhotoWidthConstraint.constant
                let imageHeight = crumbmsg.photo?.size.height
                let imageWidth = crumbmsg.photo?.size.width
                //resize photo 'height' in order to match aspect ratio
                cell.PhotoHeightConstraint.constant = ResizeImage(heightConstraint: heightConstraint, widthConstraint: widthConstraint, ImageHeight: imageHeight!, ImageWidth: imageWidth!)
                
                
                
                return cell
            } else {//MESSAGE HAS PHOTO AND MESSAGESDSDFSAGSD
                
                //imagecrumbscell BASIC SETUP
                let cell = tableView.dequeueReusableCell(withIdentifier: "imagecrumbscell", for: indexPath) as! crumbPlusImageTableViewCell
                cell.ImageViewOnCell.contentMode = .scaleAspectFill
                cell.ImageViewOnCell.image = crumbmsg!.photo
                
                cell.imageButton.addTarget(self, action: #selector(ViewCrumbViewController.imageSeggy), for: .touchUpInside)
                let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressToSave(sender:)))
                longPressRecognizer.minimumPressDuration = 0.5
                cell.imageButton.addGestureRecognizer(longPressRecognizer)
                
                cell.ImageViewOnCell.layer.cornerRadius = 5.0
                cell.ImageViewOnCell.clipsToBounds = true

                cell.ExitCrumbButton.addTarget(self, action: #selector(ViewCrumbViewController.exitCrumb), for: .touchUpInside)
                
                //Hide report button if you are the owner if not enable it
                if crumbmsg?.senderuuid == userSelf{
                    cell.ReportButton.isHidden = true///////////////////////
                    cell.ReportButton.isEnabled = false
                }else if crumbmsg?.senderuuid != userSelf{
                    cell.ReportButton.isHidden = false///////////////////////
                    cell.ReportButton.isEnabled = true

                    cell.ReportButton.tag = indexPath.row
                    cell.ReportButton.addTarget(self, action: #selector(ViewCrumbViewController.report), for: .touchUpInside)
                }
                
                
                
                //set action for create comment button
                if crumbmsg!.calculateTimeLeftInHours() > 0 {
                    cell.CommentButton.addTarget(self, action: #selector(ViewCrumbViewController.commentSegue), for: .touchUpInside)
                    cell.VoteButton.addTarget(self, action: #selector(ViewCrumbViewController.Vote), for: .touchUpInside)
                    
                } else{
                    let color = UIColor(red: 146/255, green: 144/255, blue: 144/255, alpha: 1)//greay color
                    cell.CommentButton.setTitleColor(color, for: .normal)
                    //msgCell.CreateCommentButton.addTarget(self, action: #selector(ViewCrumbViewController.noCommentIndicator), for: .touchUpInside)
                    //msgCell.VoteButton.addTarget(self, action: #selector(ViewCrumbViewController.noVoteIndicator), for: .touchUpInside)
                    
                }
                //setColorVoteButton
                if crumbmsg.isAlive(){
                    cell.CommentButton.setImage(#imageLiteral(resourceName: "comment"), for: .normal)
                    cell.CommentValueLabel.textColor = orangeColor
                } else{
                    cell.CommentButton.setImage(#imageLiteral(resourceName: "Comment-Grey"), for: .normal)
                    cell.CommentValueLabel.textColor = greyColor
                }
                
                
                
                
                //setColorVoteButton and value color
                if crumbmsg.hasVoted == 1{//user has voted
                    if crumbmsg.isAlive(){
                        cell.VoteButton.setImage(#imageLiteral(resourceName: "likeHeartfilled"), for: .normal)
                        cell.VoteValue.textColor = orangeColor
                    } else{
                        cell.VoteButton.setImage(#imageLiteral(resourceName: "likeHeartFilled-Grey"), for: .normal)
                        cell.VoteValue.textColor = greyColor
                    }
                    
                }else if crumbmsg.hasVoted == 0{
                    if crumbmsg.isAlive(){
                        cell.VoteButton.setImage(#imageLiteral(resourceName: "likeHeartEmpty"), for: .normal)
                        cell.VoteValue.textColor = orangeColor
                    } else{ //dead
                        cell.VoteButton.setImage(#imageLiteral(resourceName: "likeHearEmpty-Grey"), for: .normal)
                        cell.VoteValue.textColor = greyColor
                    }
                }
                //sets the values for the labels in the cell, time value and location value
                
                cell.CommentValueLabel.text = "\(comments.count)"
                cell.VoteValue.text = "\(crumbmsg!.votes)"
                cell.MsgTextView.text = crumbmsg!.text
                cell.UserLabel.text = crumbmsg!.senderName
                
                var textwidth = cell.UserLabel.intrinsicContentSize.width
                let contentwidth = UIScreen.main.bounds.width - 126//screen width minus total constraints and item widths + 15 padding
                if textwidth > contentwidth{
                    while textwidth > contentwidth {
                        cell.UserLabel.font = cell.UserLabel.font.withSize((cell.UserLabel.font.pointSize-1))
                        textwidth = cell.UserLabel.intrinsicContentSize.width
                    }
                }
                
                cell.TimeLabel.text = "\(crumbmsg!.dateOrganizer())"
                if crumbmsg!.calculateTimeLeftInHours() > 0 {
                    let ref = Int(crumbmsg!.calculateTimeLeftInHours())
                    
                    if ref >= 1 {
                        cell.TimeLeftLabel.text! = "\(ref)h left"//////////////////////////////////////////////////
                    }else {
                        cell.TimeLeftLabel.text = "Nearly Done!"
                    }
                } else{
                    cell.TimeLeftLabel.text! = "Time's up!"
                    
                    //Time's up indication Red Color
                    let uicolor = UIColor(red: 225/255, green: 50/255, blue: 50/255, alpha: 1)
                    cell.TimeLeftLabel.textColor = uicolor
                    //
                }
                
                
                //setColorVoteButton
                if crumbmsg?.hasVoted == 1{//user has voted
                    cell.VoteButton.setTitleColor(blueColor, for: .normal)
                }else if crumbmsg?.hasVoted == 0{
                    cell.VoteButton.setTitleColor(orangeColor, for: .normal)
                }
                
                
                ///setup to resize aspect ratio
                let heightConstraint = cell.PhotoHeightConstraint.constant
                let widthConstraint = cell.PhotoWidthConstraint.constant
                let imageHeight = crumbmsg.photo?.size.height
                let imageWidth = crumbmsg.photo?.size.width
                //resize photo 'height' in order to match aspect ratio
                cell.PhotoHeightConstraint.constant = ResizeImage(heightConstraint: heightConstraint, widthConstraint: widthConstraint, ImageHeight: imageHeight!, ImageWidth: imageWidth!)
                
                return cell

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
    
    @objc func imageSeggy(sender: UIButton){
        //print("segue to image viewer")
        self.performSegue(withIdentifier: "viewimageviewseg", sender: sender)
        
    }
    //MARK: REport
    
    @objc func report(sender: UIButton) {
        if crumbmsg!.calculateTimeLeftInHours() > 0 {
            performSegue(withIdentifier: "ReportMenuSegue", sender: sender)
            
        }else{
            let alertController = UIAlertController(title: "BreadCrumbs", message:
                "You cannot report a dead crumb as it has been deleted", preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default,handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        }

    }
    
    
    
    
    //MARK: Commenting functions
    
    // prepare view with object data;
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "writeComment") && crumbmsg!.calculateTimeLeftInHours() > 0 {
            let upcoming = segue.destination as! CreateCommentViewController
            upcoming.viewbreadcrumb = crumbmsg
            let destVC = segue.destination as! CreateCommentViewController
            destVC.delegate = self
        } else if (segue.identifier == "ReportMenuSegue") && crumbmsg!.calculateTimeLeftInHours() > 0{
        
            let upcoming = segue.destination as! ReportMenuViewController
            upcoming.delegate = self
            
            let button = sender as! UIButton
            let tag = button.tag
            if tag == 1{
                upcoming.reportedMessageId = crumbmsg?.uRecordID
                upcoming.reportedUserId = crumbmsg?.senderuuid
                upcoming.reportedtext = crumbmsg?.text
                upcoming.reporteduserID = crumbmsg?.senderuuid
                upcoming.typeToReport = "crumbmessage"
                
                if crumbmsg?.photo != nil{
                    upcoming.reportedPhoto = crumbmsg?.photo!
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
            upcoming.theImage = crumbmsg?.photo
            
        }
    }
    
    
    //createcommentdelegate function
    func addNewComment(_ newComment: CommentShort){
        //print("new comment")
        comments += [newComment]
        YourtableView.reloadData()
    }
    
    
    func loadComments(){
        let fmcom = helperFunctions.loadComments(uniqueRecordID: (crumbmsg?.uRecordID!)!)
        
        let sortedCom = fmcom.sorted(by: {$0.timeSent.timeIntervalSince1970 < $1.timeSent.timeIntervalSince1970})

        
            //sort comments by date here
        comments.append(contentsOf: sortedCom)
    }
    
    @objc func commentSegue(){
        performSegue(withIdentifier: "writeComment", sender: self)
    }//        performSegueWithIdentifier("writeComment", sender: sender)

    @objc func exitCrumb(){
        if inscreen == true{
            //saves voting stuff
            helperFunctions.crumbVote((crumbmsg?.hasVoted!)!, crumb: crumbmsg!, voteValue: votevalue )
            delegate?.reloadTables()
            //print(delegate)
            //print("run")
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
    
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
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
                self.crumbmsg = self.helperFunctions.getSpecific(recorduuid: (self.crumbmsg?.uRecordID)!)
            }else {//if user wants to refresh constantly, use both
                //button go away (blue dot)
                
                //self.PALEBLUEDOT.isHidden = true
                self.refreshNeed = false
                //also update crumb
                //ck
                self.helperFunctions.getcommentcktocd(ckidToTest: CKRecord.ID(recordName: (self.crumbmsg?.uRecordID)!))
                self.crumbmsg = self.helperFunctions.getSpecific(recorduuid: (self.crumbmsg?.uRecordID)!)
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
    
    @objc func Vote(){
        let indexPath = IndexPath(row: 1, section: 1)
        let msgCell = YourtableView.dequeueReusableCell(withIdentifier: "YourMsgCell", for: indexPath) as! CrumbTableViewCell
        
        
        //voting
        //sets a couple values according to past versions of thos values
        if crumbmsg?.hasVoted == 1 && inscreen == false{//has voted before setting vote to zero this is bad because of past structure
            inscreen = true
            crumbmsg?.hasVoted = 0
            votevalue = -1
            crumbmsg?.votes = (crumbmsg?.votes)! - 1
            
        }else if crumbmsg?.hasVoted == 0 && inscreen == false{//has not voted before +1
            inscreen = true
            crumbmsg?.hasVoted = 1
            votevalue = 1
            crumbmsg?.votes
                = (crumbmsg?.votes)! + 1
        } else if crumbmsg?.hasVoted == 1 && inscreen == true{
            crumbmsg?.hasVoted = 0
            votevalue = -1
            crumbmsg?.votes = (crumbmsg?.votes)! - 1
            
        }else if crumbmsg?.hasVoted == 0 && inscreen == true{
            crumbmsg?.hasVoted = 1
            votevalue = 1
            crumbmsg?.votes
                = (crumbmsg?.votes)! + 1
        }
        if crumbmsg?.hasVoted == 1{//resets color
            msgCell.VoteButton.setTitleColor(blueColor, for: .normal)
        }else if crumbmsg?.hasVoted == 0{
            msgCell.VoteButton.setTitleColor(orangeColor, for: .normal)
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
            "You cannot comment on a dead crumb", preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default,handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func noVoteIndicator(){
        let alertController = UIAlertController(title: "BreadCrumbs", message:
            "You cannot vote on a dead crumb", preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default,handler: nil))
        
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
    @objc func longPressToSave(sender: UILongPressGestureRecognizer) {
        //use popover revopop\\\poppy im poppy popover///\\\(((Rootless cosmopolitans)))
        SaveCancelMenuView.isHidden = false
    }
    
    func saveimagePopUp(){
        UIImageWriteToSavedPhotosAlbum((crumbmsg?.photo)!, self, #selector(image(image:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(image: UIImage!, didFinishSavingWithError error: NSError!, contextInfo: AnyObject!) {
        if (error != nil) {
            print(error)
            
        } else {
            print("alright")
        }
    }
    
}
extension ViewCrumbViewController{
    /**
     *Helps resize photos by outputing new constraints based on the image's height and width*
     
     */
    func ResizeImage(heightConstraint: CGFloat, widthConstraint: CGFloat, ImageHeight: CGFloat, ImageWidth: CGFloat
        ) -> CGFloat{
        //NOTE Aspect Ratio is W:H
        var newHeightConstraint: CGFloat = 300
        let aspectRatio: CGFloat = (ImageWidth)/(ImageHeight)
        
        if (1.01 < aspectRatio) && (aspectRatio <= 2){// landscape
            newHeightConstraint = newHeightConstraint / aspectRatio
            //it will always be 300 wide although may want to grab that width constraint
            //incase later we need to resize due to phone sizes
        } else if aspectRatio <= 1.01{//force square on square and verticals
            newHeightConstraint = 300
        }
        
        return newHeightConstraint
    }
}

//reloads table in yours or others in order to persist vote button colors colors
protocol NewOthersCrumbsViewControllerDelegate: class {
    func reloadTables()
}

