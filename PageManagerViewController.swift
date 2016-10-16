//
//  PageManagerViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 4/30/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import Foundation
import UIKit

class PageManagerViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate  {
    
    //MARK: Variables
    var indexcounter = 0
    var identifiers: NSArray = ["UserView", "YourCurrentBreadCrumbs", "OthersCurrentBreadCrumbs"]
    
    
    //MARK: view loading
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource = self
        self.delegate = self
        
        let startingView = self.viewControllerAtIndex(self.indexcounter)
        let mainViews: NSArray = [startingView]
        self.setViewControllers(mainViews as? [UIViewController], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
        
        /*I dont really understand what to do here
         it is strange
         how do i persist data? <- SOLVED
         will western culture survive? <- MAYBE
         what am I doing wrong here?
         fuck.*/
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //it doubles the second viewcontroller:::FIXED <3
    //also if one swipes right then left, the 3 view is never instantiated:::FIXED <3

    func viewControllerAtIndex(index: Int) -> UINavigationController! {
        //This method creates a new instance of the specified view controller each time you call it.
              
        //UserView
        if index == 0 {
            return self.storyboard!.instantiateViewControllerWithIdentifier("UserView") as! UINavigationController
        }
        
        //Your bread crumb table view controller view
        if index == 1 {
            return self.storyboard!.instantiateViewControllerWithIdentifier("YourCurrentBreadCrumbs") as! UINavigationController

        }
        
        //Other users bread crumb table view controller view
        if index == 2 {
            return self.storyboard!.instantiateViewControllerWithIdentifier("OthersCurrentBreadCrumbs") as! UINavigationController

        }
        
        return nil
    }
    
    
    //MARK: pageviewcontrollerdatasource
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        let identifier = viewController.restorationIdentifier
        let index = self.identifiers.indexOfObject(identifier!)
        
        //var restorationID = restorationIdentifier;

        //print(restorationID)
        //limits pages
        if index == 2 {
            return nil
        }
        
        //UIViewController *vc = self.window.rootViewController;

        
        //increment the index to get the viewController after the current index
        self.indexcounter = index + 1
        return self.viewControllerAtIndex(self.indexcounter)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        let identifier = viewController.restorationIdentifier
        let index = self.identifiers.indexOfObject(identifier!)
        
        //limits swiping back
        if index == 0 {
            return nil
        }
        
        //decrement the index to get the viewController before the current one
        self.indexcounter = index - 1
        return self.viewControllerAtIndex(self.indexcounter)
    }
    
}
//a comment was once here; now no-one can know what it said


