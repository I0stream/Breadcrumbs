//
//  TabsViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 2/10/17.
//  Copyright © 2017 Daniel Schliesing. All rights reserved.
//

import UIKit

class TabsViewController: UITabBarController {

    let NSUserData = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if NSUserData.integer(forKey: "otherExplainer") == 2{
            self.tabBar.items![1].badgeValue = ""
            NSUserData.setValue(0, forKey: "otherExplainer")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
