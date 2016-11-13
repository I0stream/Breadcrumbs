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
    
    @IBOutlet weak var ExitCrumbButton: UIButton!
    
    @IBOutlet weak var CreateCommentButton: UIButton!
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
    
    @IBAction func VoteAction(sender: AnyObject) {
//        counter = 1
        
    }
}
