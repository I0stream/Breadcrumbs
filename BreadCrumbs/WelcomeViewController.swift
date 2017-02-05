//
//  WelcomeViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 1/20/17.
//  Copyright © 2017 Daniel Schliesing. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {

    let NSUserData = UserDefaults.standard//for storing states and numbers

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        NSUserData.set("welcome", forKey: "welcomeValue")//) = "welcome"

        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func StartButton(_ sender: Any) {
        //let vc = storyboard?.instantiateViewController(withIdentifier: "pgManager") as! PageManagerViewController
        //ShowPg
        performSegue(withIdentifier: "ShowPg", sender: self)
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
