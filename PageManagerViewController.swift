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
    var identifiers: NSArray = ["IntroShill", "Intro-2", "Intro-3", "SignIn"]
    
    
    //MARK: view loading
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource = self
        self.delegate = self
        
        let startingView = self.viewControllerAtIndex(self.indexcounter)
        let mainViews = [startingView]//if it breaks this is the problem, changed from nsarray to emplied uivc
        self.setViewControllers(mainViews as? [UIViewController], direction: UIPageViewControllerNavigationDirection.forward, animated: false, completion: nil)
        
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

    func viewControllerAtIndex(_ index: Int) -> UIViewController! {
        //This method creates a new instance of the specified view controller each time you call it.
              
        //UserView
        if index == 0 {
            return self.storyboard!.instantiateViewController(withIdentifier: "IntroShill") 
        }
        
        //Your bread crumb table view controller view
        if index == 1 {
            return self.storyboard!.instantiateViewController(withIdentifier: "Intro-2")

        }
        
        //Other users bread crumb table view controller view
        if index == 2 {
            return self.storyboard!.instantiateViewController(withIdentifier: "Intro-3")

        }
        if index == 3{
            return self.storyboard!.instantiateViewController(withIdentifier: "SignIn") 
        }
        
        return nil
    }
    
    
    //MARK: pageviewcontrollerdatasource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        let identifier = viewController.restorationIdentifier
        let index = self.identifiers.index(of: identifier!)
        
        //var restorationID = restorationIdentifier;

        //print(restorationID)
        //limits pages
        if index == 3 {
            return nil
        }
        
        //UIViewController *vc = self.window.rootViewController;

        
        //increment the index to get the viewController after the current index
        self.indexcounter = index + 1
        return self.viewControllerAtIndex(self.indexcounter)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        let identifier = viewController.restorationIdentifier
        let index = self.identifiers.index(of: identifier!)
        
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


