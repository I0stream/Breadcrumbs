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
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    

}
