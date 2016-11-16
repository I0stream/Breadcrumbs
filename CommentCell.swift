//
//  TableViewCell.swift
//  scrollviewtest
//
//  Created by Daniel Schliesing on 11/1/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import UIKit

class CommentCell: UITableViewCell {

    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var CommentTextView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
