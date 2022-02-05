//
//  WebTableViewCell.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 3/22/17.
//  Copyright © 2017 Daniel Schliesing. All rights reserved.
//

import UIKit

class WebTableViewCell: UITableViewCell {

    
    @IBOutlet weak var TimeRemainingValueLabel: UILabel!
    //    @IBOutlet weak var LocationPosted: UILabel!
    @IBOutlet weak var TextViewCellOutlet: UITextView!
    @IBOutlet weak var VoteValue: UILabel!
    @IBOutlet weak var YouTheUserLabel: UILabel!
    @IBOutlet weak var timeCountdown: UILabel!
    @IBOutlet weak var VoteButton: UIButton!
    
    //@IBOutlet weak var webPreviewImageWebView: WKWebView!
    
    @IBOutlet weak var webPreviewTextLabel: UILabel!
    @IBOutlet weak var webSegueButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
