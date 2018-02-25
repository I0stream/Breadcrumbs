//
//  NotificationNotifierTableViewCell.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 2/11/18.
//  Copyright © 2018 Daniel Schliesing. All rights reserved.
//

import UIKit

class NotificationNotifierTableViewCell: UITableViewCell {

    @IBOutlet weak var AllowButton: UIButton!
    @IBOutlet weak var DontAllowButton: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
