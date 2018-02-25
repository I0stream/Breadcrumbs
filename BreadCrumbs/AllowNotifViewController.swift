//
//  AllowNotifViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 2/9/18.
//  Copyright © 2018 Daniel Schliesing. All rights reserved.
//

import UIKit

class AllowNotifViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func AllowNotif(_ sender: Any) {
        //get permissions
        performSegue(withIdentifier: "SegToAgreement", sender: nil)
    }
    @IBAction func DontAllowNotif(_ sender: Any) {
        let alert = UIAlertController(title: "Alert", message: "Message", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        //let them know with a alert they can change it in settings
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
