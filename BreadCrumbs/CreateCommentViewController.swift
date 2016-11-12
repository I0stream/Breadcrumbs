//
//  CreateCommentViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 11/8/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import UIKit

class CreateCommentViewController: UIViewController {

    @IBOutlet weak var WriteCommentTextView: UITextView!
    
    weak var delegate: CreateCommentDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func CancelComment(sender: AnyObject) {
    }

    
    @IBAction func MakeComment(sender: AnyObject) {
    }
}

protocol CreateCommentDelegate: class {
   func addNewComment(newComment: Comment)
}
