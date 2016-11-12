//
//  CrumbTableViewCell.swift
//  scrollviewtest
//
//  Created by Daniel Schliesing on 11/2/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import UIKit
import MapKit

class CrumbTableViewCell: UITableViewCell, UITextViewDelegate{
    
    //What i am doing in this cell is probably looked down upon by apple
    //however, if this fuckking works i will be so excited
    
    //MARK: Properties
    //@IBOutlet weak var mapViewOutlet: MKMapView!
    @IBOutlet weak var MsgTextView: UITextView!
    @IBOutlet weak var UserLabel: UILabel!
    @IBOutlet weak var TimeLabel: UILabel!
    @IBOutlet weak var TimeLeftLabel: UILabel!
    
    
    //@IBOutlet weak var LocationLabel: UILabel!
    //@IBOutlet weak var countdownLabel: UILabel!
    
    var viewbreadcrumb: CrumbMessage?
    var counter: Int?
    var hasVotedInScreen: Bool?
    var theVoteValueToBeStored: Int?
    var timer = NSTimer()

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        //self.MsgTextView.delegate = self
        //self.mapViewOutlet.delegate = self
        //self.mapViewOutlet.mapType = MKMapType.Standard
        
        
        /*//fix font size
        OtherMsgTextView.font = UIFont.systemFontOfSize(17)
        */
        //autodefine textview size
        let fixedWidth = MsgTextView.frame.size.width
        MsgTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        let newSize = MsgTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        var newFrame = MsgTextView.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        MsgTextView.frame = newFrame;
        
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func CreateCommentButton(sender: AnyObject) {
        //delegate
        //performSegueWithIdentifier("writeComment", sender: sender)
    }
    
    @IBAction func VoteAction(sender: AnyObject) {
//        counter = 1
        
    }
    
    
    @IBAction func ExitCrumbButton(sender: AnyObject) {
        //delegate!
        //dismissViewControllerAnimated(true, completion: nil)
    }
    
    /*func countingDown(){
        if viewbreadcrumb!.calculate() > 0 {
            var countdownHolder = viewbreadcrumb!.countdownTimerSpecific()
            countdownHolder = countdownHolder - 1
            
            converterUpdater(countdownHolder)
        } else {
            timer.invalidate()
            countdownLabel.text = "Time's up!"
        }
    }*/
    
    /*func converterUpdater(countdownHolder: Int){
        //var days = String(round(countdownHolder / 86400))
        var hours = String(countdownHolder / 3600)
        var minutes = String((countdownHolder % 3600) / 60)
        var seconds = String(countdownHolder % 60)
        
        
        if Int(hours) < 10{
            hours = "0\(hours)"
        }
        if Int(minutes) < 10{
            minutes = "0\(minutes)"
        }
        if Int(seconds) < 10{
            seconds = "0\(seconds)"
        }
        
        countdownLabel.text = "\(hours):\(minutes):\(seconds) left"
    }*/
    
    //if never vote +1, if changing vote if voted before positive
    
    //this code is so fucking bad and complicated and utterly confusing, I want to rewrite this so bad, but I dont know how to do it differently
    //i rewrote it, it is still confusing, i think its just the things im trying to do
    /*@IBAction func UPVOTE(sender: AnyObject) {
        
        print(counter)
        print(viewbreadcrumb?.hasVoted)
        if counter == 0 && viewbreadcrumb?.hasVoted == 0{//if you havent voted in screen and never voted on this before
            //vote +1
            theVoteValueToBeStored = (viewbreadcrumb?.votes)! + 1
            updootColor.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
            downdootColor.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)
            UpVoteValueLabel.text = String(viewbreadcrumb!.votes! + 1)
            counter = 1
            hasVotedInScreen = true
        } else if counter == -1 && viewbreadcrumb?.hasVoted == 0{//changing vote in screen to pos
            //vote +2
            theVoteValueToBeStored = (viewbreadcrumb?.votes)! + 1
            updootColor.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
            downdootColor.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)
            UpVoteValueLabel.text = String(viewbreadcrumb!.votes! + 1)
            counter = 1
            hasVotedInScreen = true
        } else if counter == -1 && viewbreadcrumb?.hasVoted == -1{//changing vote from outside
            //vote +2
            theVoteValueToBeStored = (viewbreadcrumb?.votes)! + 1/////////////
            updootColor.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
            downdootColor.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)
            UpVoteValueLabel.text = String(viewbreadcrumb!.votes! + 1)
            counter = 1
            hasVotedInScreen = true
        } else if counter == -1 && viewbreadcrumb?.hasVoted == 1 {//changing vote from outside and inside
            //ignore change no restoring and shieet
            theVoteValueToBeStored = (viewbreadcrumb?.votes)!
            updootColor.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
            downdootColor.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)
            UpVoteValueLabel.text = String(viewbreadcrumb!.votes!)
            counter = 1
            hasVotedInScreen = true
        } else if counter == -1 && viewbreadcrumb?.hasVoted == -1{
            theVoteValueToBeStored = (viewbreadcrumb?.votes)! + 1
            updootColor.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
            downdootColor.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)
            UpVoteValueLabel.text = String(viewbreadcrumb!.votes! + 1)
            counter = 1
            hasVotedInScreen = true
        }
        
    }
    @IBAction func DOWNVOTE(sender: AnyObject) {
        print(counter)
        print(viewbreadcrumb?.hasVoted)
        if counter == 0 && viewbreadcrumb?.hasVoted == 0{//if you havent voted in screen and never voted on this before
            //vote -1
            theVoteValueToBeStored = (viewbreadcrumb?.votes)! - 1
            downdootColor.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
            updootColor.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)
            UpVoteValueLabel.text = String(viewbreadcrumb!.votes! - 1)
            counter = -1
            hasVotedInScreen = true
        } else if counter == 1 && viewbreadcrumb?.hasVoted == 0{//changing vote in screen to pos
            //vote -2
            theVoteValueToBeStored = (viewbreadcrumb?.votes)! - 1
            downdootColor.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
            updootColor.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)
            UpVoteValueLabel.text = String(viewbreadcrumb!.votes! - 1)
            counter = -1
            hasVotedInScreen = true
        } else if counter == 1 && viewbreadcrumb?.hasVoted == 1{//changing vote from outside
            //vote -2
            theVoteValueToBeStored = (viewbreadcrumb?.votes)! - 1///////////////
            downdootColor.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
            updootColor.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)
            UpVoteValueLabel.text = String(viewbreadcrumb!.votes! - 1)
            counter = -1
            hasVotedInScreen = true
        } else if counter == 1 && viewbreadcrumb?.hasVoted == -1 {//changing vote from outside and inside
            //ignore change pretty much
            theVoteValueToBeStored = (viewbreadcrumb?.votes)!
            downdootColor.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
            updootColor.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)
            UpVoteValueLabel.text = String(viewbreadcrumb!.votes!)
            counter = -1
            hasVotedInScreen = true
        } else if counter == 1 && viewbreadcrumb?.hasVoted == 1{
            theVoteValueToBeStored = (viewbreadcrumb?.votes)! - 1
            downdootColor.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
            updootColor.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)
            UpVoteValueLabel.text = String(viewbreadcrumb!.votes! - 1)
            counter = -1
            hasVotedInScreen = true
        }
    }*/
}
