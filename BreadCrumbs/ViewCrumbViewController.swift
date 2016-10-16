//
//  ViewCrumbViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 4/22/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import UIKit
import MapKit

class ViewCrumbViewController: UIViewController, UITextViewDelegate, MKMapViewDelegate {
    
    
    
    //MARK: Properties
    
    @IBOutlet weak var crumbMessageTextView: UITextView!
    @IBOutlet weak var crumbPosterLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var timeLeftForCrumbLabel: UILabel!
    @IBOutlet weak var voteValueLabel: UILabel!
    @IBOutlet weak var mapViewOutlet: MKMapView!
    @IBOutlet weak var countdownLabel: UILabel!
    
    //MARK: Variables
    
    let helperFunctions = Helper()//for updateVoteValue
    var viewbreadcrumb: CrumbMessage?
    var timer = NSTimer()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //init
        
        
        self.crumbMessageTextView.delegate = self
        self.mapViewOutlet.delegate = self
        self.mapViewOutlet.mapType = MKMapType.Standard
        
        if viewbreadcrumb!.calculate() > 0 {
            let countdownHolder = viewbreadcrumb!.countdownTimerSpecific()
            
            converterUpdater(countdownHolder)
            
            timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(ViewCrumbViewController().countingDown), userInfo: nil, repeats: true)
        } else {
            countdownLabel.text = "Time's up!"
        }
        //init
        
        //TextView border
        crumbMessageTextView.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).CGColor
        self.crumbMessageTextView.layer.borderWidth = 1.0;
        self.crumbMessageTextView.layer.cornerRadius = 5.0;
        
        //reset text justification to default
        self.automaticallyAdjustsScrollViewInsets = false
        
        //set up views for existing crumbs
        crumbMessageTextView.text = viewbreadcrumb?.text
        crumbPosterLabel.text = (viewbreadcrumb?.senderName)! + " "
        timeLeftForCrumbLabel.text = "\(viewbreadcrumb!.dateOrganizer())"
        voteValueLabel.text = "\(String(viewbreadcrumb!.votes!))"
        
        if viewbreadcrumb!.calculate() > 0 {

        } else {
            countdownLabel.text = "Time's up!"
        }
        
        if viewbreadcrumb?.addressStr != nil {
            locationLabel.text = viewbreadcrumb?.addressStr
        }else{
            locationLabel.text = "Address error"
        }
        
        //fix font size
        crumbMessageTextView.font = UIFont.systemFontOfSize(17)
        
        //autodefine textview size
        let fixedWidth = crumbMessageTextView.frame.size.width
        crumbMessageTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        let newSize = crumbMessageTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        var newFrame = crumbMessageTextView.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        crumbMessageTextView.frame = newFrame;
        
        //anotations
        let mkAnnoTest = MKPointAnnotation.init()
        mkAnnoTest.coordinate = viewbreadcrumb!.location.coordinate
        mapViewOutlet.addAnnotation(mkAnnoTest)
        
        mapViewOutlet.camera.centerCoordinate = viewbreadcrumb!.location.coordinate
        
        mapViewOutlet.camera.altitude = 1000
        
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
        
    func countingDown(){
        if viewbreadcrumb!.calculate() > 0 {
            var countdownHolder = viewbreadcrumb!.countdownTimerSpecific()
            countdownHolder = countdownHolder - 1
            
            converterUpdater(countdownHolder)
        } else {
            timer.invalidate()
            countdownLabel.text = "Time's up!"
        }
    }
    func converterUpdater(countdownHolder: Int){
        //var days = String(countdownHolder / 86400)
        var hours = String(countdownHolder / 3600)
        var minutes = String((countdownHolder % 3600) / 60)
        var seconds = String(countdownHolder % 60)
        
        
        if Int(hours) < 10{
            hours = "0\(hours)"
        }
        if Int(minutes) < 10{
            minutes = "0\(minutes)"
        }
        if Int(seconds) < 10{
            seconds = "0\(seconds)"
        }
        
        countdownLabel.text = "\(hours):\(minutes):\(seconds) left"
    }
    
}
