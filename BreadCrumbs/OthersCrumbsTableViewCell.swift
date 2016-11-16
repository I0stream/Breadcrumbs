//
//  OthersCrumbsTableViewCell.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 4/28/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import UIKit

class OthersCrumbsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var PosterUserNameLabel: UILabel!
    @IBOutlet weak var othersMessageTextView: UITextView!
    @IBOutlet weak var TimeAgoPosted: UILabel!
    @IBOutlet weak var OthersVotesLabe: UILabel!
    @IBOutlet weak var OthersAddress: UILabel!
    @IBOutlet weak var TimeCountdown: UILabel!
    @IBOutlet weak var IsViewedLabel: UILabel!

    
    @IBOutlet weak var UpvoteOutlet: UIButton!
    
    @IBOutlet weak var DownvoteOutlet: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    @IBAction func UpvoteAction(_ sender: AnyObject) {
    }
    @IBAction func DownvoteAction(_ sender: AnyObject) {
    }
    

}
