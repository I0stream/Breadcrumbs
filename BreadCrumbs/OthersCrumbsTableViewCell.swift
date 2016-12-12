//
//  OthersCrumbsTableViewCell.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 4/28/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import UIKit

class OthersCrumbsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var TimeRemainingValueLabel: UILabel!
    //    @IBOutlet weak var LocationPosted: UILabel!
    @IBOutlet weak var TextViewCellOutlet: UITextView!
    @IBOutlet weak var VoteValue: UILabel!
    @IBOutlet weak var YouTheUserLabel: UILabel!
    @IBOutlet weak var timeCountdown: UILabel!
    @IBOutlet weak var VoteButton: UIButton!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        //NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(YourCrumbsTableViewCell().countinDown), userInfo: nil, repeats: true)
        
        // Configure the view for the selected state
    }
    

    

}
