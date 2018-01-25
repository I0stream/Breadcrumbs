//
//  PhotoOnlyTableViewCell.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 1/23/18.
//  Copyright © 2018 Daniel Schliesing. All rights reserved.
//

import UIKit

class PhotoOnlyTableViewCell: UITableViewCell {

    @IBOutlet weak var YouTheUserLabel: UILabel!
    @IBOutlet weak var TimeRemainingValueLabel: UILabel!
    @IBOutlet weak var timeCountdown: UILabel!
    
    @IBOutlet weak var ReportButton: UIButton!
    
    
    @IBOutlet weak var imageButton: UIButton!
    @IBOutlet weak var VoteValue: UILabel!
    @IBOutlet weak var VoteButton: UIButton!
    
    @IBOutlet weak var UserUploadedPhotoUIView: UIImageView!
    
    @IBOutlet weak var CommentButton: UIButton!
    @IBOutlet weak var CommentValueLabel: UILabel!
    
    var viewbreadcrumb: CrumbMessage?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}
