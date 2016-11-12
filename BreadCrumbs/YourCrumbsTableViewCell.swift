//
//  CrumbMessageTableViewCell.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 4/18/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import UIKit

class YourCrumbsTableViewCell: UITableViewCell {

    //MARK: Properties
    
    @IBOutlet weak var TimeRemainingValueLabel: UILabel!
//    @IBOutlet weak var LocationPosted: UILabel!
    @IBOutlet weak var TextViewCellOutlet: UITextView!
    @IBOutlet weak var VoteValue: UILabel!
    @IBOutlet weak var YouTheUserLabel: UILabel!
    @IBOutlet weak var timeCountdown: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        //NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(YourCrumbsTableViewCell().countinDown), userInfo: nil, repeats: true)

        // Configure the view for the selected state
    }

    @IBAction func editActionButton(sender: AnyObject) {//for deleting msgs only yours
        print("pressed")//probably do this through delegation
        //delegate button pressed
        //cell index to open this cells editing
        //press red button to delete
    }

    //MARK: Actions
    
}
