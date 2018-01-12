//
//  crumbPlusImageTableViewCell.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 2/28/17.
//  Copyright © 2017 Daniel Schliesing. All rights reserved.
//

import UIKit

class crumbPlusImageTableViewCell: UITableViewCell, UITextViewDelegate {

    @IBOutlet weak var MsgTextView: UITextView!
    @IBOutlet weak var UserLabel: UILabel!
    @IBOutlet weak var TimeLabel: UILabel!
    @IBOutlet weak var TimeLeftLabel: UILabel!
    @IBOutlet weak var ExitCrumbButton: UIButton!
    
    @IBOutlet weak var ReportButton: UIButton!
    
    
    @IBOutlet weak var imageButton: UIButton!
    @IBOutlet weak var VoteValue: UILabel!
    @IBOutlet weak var VoteButton: UIButton!
    
    @IBOutlet weak var ImageViewOnCell: UIImageView!
    
    @IBOutlet weak var CommentButton: UIButton!
    @IBOutlet weak var CommentValueLabel: UILabel!
    
    var viewbreadcrumb: CrumbMessage?
    
    
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
        MsgTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        let newSize = MsgTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        var newFrame = MsgTextView.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        MsgTextView.frame = newFrame;
        
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
