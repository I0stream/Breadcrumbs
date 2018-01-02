//
//  ImageMessageTableViewCell.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 2/23/17.
//  Copyright © 2017 Daniel Schliesing. All rights reserved.
//

import UIKit

class ImageMessageTableViewCell: UITableViewCell {

    
    @IBOutlet weak var RepostButton: UIButton!
    
    
    
    @IBOutlet weak var TimeRemainingValueLabel: UILabel!
    //    @IBOutlet weak var LocationPosted: UILabel!
    @IBOutlet weak var TextViewCellOutlet: UITextView!
    @IBOutlet weak var VoteValue: UILabel!
    @IBOutlet weak var YouTheUserLabel: UILabel!
    @IBOutlet weak var timeCountdown: UILabel!
    @IBOutlet weak var VoteButton: UIButton!
    @IBOutlet weak var ReportButton: UIButton!
    @IBOutlet weak var UserUploadedPhotoUIView: UIImageView!
    @IBOutlet weak var imageButton: UIButton!
    
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
