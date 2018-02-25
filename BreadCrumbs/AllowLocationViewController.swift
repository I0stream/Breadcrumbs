//
//  AllowLocationViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 2/9/18.
//  Copyright © 2018 Daniel Schliesing. All rights reserved.
//

import UIKit
import UserNotifications
import CoreLocation

class AllowLocationViewController: UIViewController, UNUserNotificationCenterDelegate, CLLocationManagerDelegate{

    var timerLocationHandler = Timer()
    var locationmanager = AppDelegate().locationManager
    override func viewDidLoad() {
        super.viewDidLoad()
        //CLLocationManager().delegate = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func timerHandler(){
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .restricted, .denied:
                print("restrect")
                timerLocationHandler.invalidate()

                let alertController = UIAlertController(title: "BreadCrumbs", message:
                    "Please set location permissions to \"Always\" in the settings menu on your Phone.", preferredStyle: UIAlertControllerStyle.alert)
                
                alertController.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: {_ in
                    CATransaction.setCompletionBlock({
                        self.doSeg()
                    })
                }))
                self.present(alertController, animated: true, completion: nil)
                
            case .authorizedAlways, .authorizedWhenInUse:
                print("authed")
                timerLocationHandler.invalidate()
                doSeg()
            case .notDetermined:
                print("notdetermed")
            }
        }
    }
    
    
    @IBAction func AllowLocation(_ sender: Any) {
       
       
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined:
                print("not det")
                locationmanager.requestAlwaysAuthorization()
                timerLocationHandler = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerHandler), userInfo: nil, repeats: true)

                //finisher with a seg
            case .restricted, .denied:
                print("restrect")
                
                let alertController = UIAlertController(title: "BreadCrumbs", message:
                    "Please set location permissions to \"Always\" in the settings menu on your Phone.", preferredStyle: UIAlertControllerStyle.alert)
                
                alertController.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: {_ in
                    CATransaction.setCompletionBlock({
                        self.doSeg()
                    })
                }))
                self.present(alertController, animated: true, completion: nil)
                
            case .authorizedAlways, .authorizedWhenInUse:
                print("authed")
                    doSeg()
                
            }
        } else {
            let alertController = UIAlertController(title: "BreadCrumbs", message:
                "Please set location permissions to \"Always\" in the settings menu on your Phone.", preferredStyle: UIAlertControllerStyle.alert)
            
            alertController.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: {_ in
                CATransaction.setCompletionBlock({
                    self.doSeg()
                })
            }))
        }
    }
 
    
    @IBAction func DontAllowLocation(_ sender: Any) {
        timerLocationHandler.invalidate()
        let alertController = UIAlertController(title: "BreadCrumbs", message:
            "Location services and the receiving of messages are both disabled. If you change your mind, these options can be enabled in settings.", preferredStyle: UIAlertControllerStyle.alert)
        
        alertController.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: {_ in
            CATransaction.setCompletionBlock({
                self.doSeg()
            })
        }))
        
        self.present(alertController, animated: true, completion: nil)
        //let them know with a alert they can change it in settings
    }
    
    func doSeg(){
        performSegue(withIdentifier: "SegToAgree", sender: nil)
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
