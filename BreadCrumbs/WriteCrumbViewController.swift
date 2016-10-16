
//
//  WriteCrumbViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 4/9/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//


//WE NEED TO RENAME OUR VARIABLES; It is fucking confusing
//Fucking amateur

import CloudKit
import UIKit
import CoreLocation
import CoreData

class WriteCrumbViewController: UIViewController, UITextViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource, CLLocationManagerDelegate {
    
    //MARK: Variables
    var msgCharCount:Int = 0
    var timeDroppedvar: String?
    var pickerTimeLimit = ["4","8","12","24"]
    let NSUserData = NSUserDefaults.standardUserDefaults()
    let locationManager: CLLocationManager = AppDelegate().locationManager
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext //yay
    let helperfunctions = Helper()

    
    /*
     This value is either passed by `yourcrumbTableViewController` in `prepareForSegue(_:sender:)`
     or constructed as part of adding a new CrumbMessage.
     */
    var crumbmessage: CrumbMessage?
    
    
    //MARK: Properties
    
    @IBOutlet weak var msgTimePickerField: UIPickerView!
    
    @IBOutlet weak var barCrumbCounterNumber: UIBarButtonItem!
    @IBOutlet weak var crumbMessageTextView: UITextView!
    @IBOutlet weak var charLabelCount: UILabel!
    @IBOutlet weak var postButtonOutlet: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        postButtonOutlet.enabled = false
        
        // Handle the text field’s user input through delegate callbacks.
        self.msgTimePickerField.dataSource = self
        self.msgTimePickerField.delegate = self
        self.crumbMessageTextView.delegate = self
        
        textViewDidChange(crumbMessageTextView)
        
        //TextView border
        crumbMessageTextView.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).CGColor
        self.crumbMessageTextView.layer.borderWidth = 1.0;
        self.crumbMessageTextView.layer.cornerRadius = 5.0;
        self.automaticallyAdjustsScrollViewInsets = false//fuck yeah fixed it

        
        //populate crumb counter number
        barCrumbCounterNumber.title = "\(NSUserData.stringForKey("crumbCount")!)/5"
        
        //msgView(textView) placeholder text
        crumbMessageTextView.text = "Write your message here."
        crumbMessageTextView.textColor = UIColor.lightGrayColor()
        
        //fuck if I know, post button off unless pass tests
        postButtonEnabledIfTestsTrue()
        
        self.hideKeyboardWhenTappedAround()
        
        
        let check = checkLocation()//i dont remember writing this
        if check {
            helperfunctions.testStoredMsgsInArea(locationManager.location!)
        }
        
        if AppDelegate().NSUserData.integerForKey("limitArea") == 1{
            print("too many crumbs in area, please walk to another location and try again")//have and indicator
        }
    }


    
    //MARK: ICloud and Coredata
    
    func UpdateCrumbCount(cCount: Int){
        
        let recordID = NSUserData.stringForKey("recordID")!

        let specificID = CKRecordID(recordName: "\(recordID)")
        
        let container = CKContainer.defaultContainer()
        let publicData = container.publicCloudDatabase
        
        
        publicData.fetchRecordWithID(specificID, completionHandler: {record, error in
            if error == nil{
                record!.setObject(cCount, forKey: "crumbCount")
                //print("updated crumbcount, check cloud database")
                
                publicData.saveRecord(record!, completionHandler: {theRecord, error in
                    if error == nil{
                        print("saved version")
                    }else{
                        print(error)
                    }
                })
            }else{
                print("error")
            }
        })
    
    }
    
    func saveToCloud(crumbmessage: CrumbMessage?){
        
        //upload to iCloud
        
        let container = CKContainer.defaultContainer()
        let publicData = container.publicCloudDatabase
        
        let record = CKRecord(recordType: "CrumbMessage")
        
        record.setValue(crumbmessage?.location, forKey: "location")
        record.setValue(crumbmessage?.senderName, forKey: "senderName")
        record.setValue(crumbmessage?.text, forKey: "text")
        record.setValue(crumbmessage?.timeDropped, forKey: "timeDropped")
        record.setValue(crumbmessage?.timeLimit, forKey: "timeLimit")
        record.setValue(crumbmessage?.senderuuid, forKey: "senderuuid")
        record.setValue(crumbmessage?.votes, forKey: "votes")
        
        publicData.saveRecord(record, completionHandler: { record, error in
            if error != nil {
                print(error.debugDescription)
            }
        })
    }
    
    func saveToCoreData(crumbmessage: CrumbMessage){
        
        //create Message: NSManagedObject
        
        let messageMO = NSEntityDescription.insertNewObjectForEntityForName("Message", inManagedObjectContext: self.managedObjectContext) as! BreadCrumbs.Message
        
        messageMO.setValue(crumbmessage.text, forKey: "text")
        messageMO.setValue(crumbmessage.senderName, forKey: "senderName")
        messageMO.setValue(crumbmessage.timeDropped, forKey: "timeDropped")
        messageMO.setValue(crumbmessage.timeLimit, forKey: "timeLimit")
        messageMO.initFromLocation(crumbmessage.location)
        messageMO.setValue(crumbmessage.senderuuid, forKey: "senderuuid")
        messageMO.setValue(crumbmessage.votes, forKey: "votevalue")
        messageMO.setValue(NSUUID().UUIDString, forKey: "recorduuid")
        messageMO.setValue(crumbmessage.addressStr, forKey: "addressStr")

        
        do {
            try messageMO.managedObjectContext?.save()
            //print("saved to coredata")
        } catch {
            print(error)
        }

    }
    
    //add crumb to coredata
    func addCrumbCDAndCK(sender: AnyObject?) {
        if postButtonOutlet === sender{
            if testMsg() == true && checkLocation() == true && AppDelegate().NSUserData.integerForKey("limitArea") == 0 {
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                
                let cCounter: Int = Int(NSUserData.stringForKey("crumbCount")!)! - 1
                //print(cCounter)
                
                NSUserData.setValue(cCounter, forKey: "crumbCount")
                self.UpdateCrumbCount(cCounter)
                
                barCrumbCounterNumber.title = "\(NSUserData.stringForKey("crumbCount")!)/5"
                
                let senderUser = NSUserData.stringForKey("userName")!
                let date = NSDate()
                let timeChoice = Int(pickerTimeLimit[msgTimePickerField.selectedRowInComponent(0)])
                
                //create crumbMessage object
                crumbmessage = CrumbMessage(text: crumbMessageTextView.text, senderName: senderUser, location: locationManager.location!, timeDropped: date, timeLimit: timeChoice!, senderuuid: NSUserData.stringForKey("recordID")!, votes: 1)
                
                crumbmessage!.convertCoordinatesToAddress((crumbmessage!.location), completion: { (answer) in
                    self.crumbmessage!.addressStr = answer!
                    
                    self.saveToCoreData(self.crumbmessage!)
                    self.saveToCloud(self.crumbmessage)//saves without msg
                    
                    self.NSUserData.setValue(NSDate(), forKey: "SinceLastCheck")
                    
                    NSNotificationCenter.defaultCenter().postNotificationName("loadYours", object: nil)
                    self.dismissViewControllerAnimated(true, completion: nil)
                    
               })//NEED ERROR HANDLING HERE

                
            } else {
                print("Tests did fail :(")/*I need to add an indicator and disable the post button if the
                 tests are failing; like jesus it makes testing shit a pain in my ass whenever I sim it
                 the loc services dont auto run half the time and then I have to dick around with it*/
            }
        }
    }
    
    
    //MARK: prereqs and misc checks
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: PickerView Methods
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerTimeLimit.count;
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerTimeLimit[row]
    }
    
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(WriteCrumbViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    //MARK: msgTextView Methods
    
    //test if crumb passes length and if enough crumbs
    func testMsg() -> Bool{
        //success case; have enough crumbs and length is proper
        if Int(NSUserData.stringForKey("crumbCount")!) > 0 && msgLengthTest(){
            
            return true
        } else if msgLengthTest() == false{ //fail case; length is incorrect
            print("Length error")
            return false
            
        } else { //fail case; user has no remaining messages
            
            //alert user they are out of msgs
            
            let alert = UIAlertController(title: "Error", message: "You are out of crumbs, wait X more minutes to receive more", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            
            return false
        }
    }
    
    //track chars in msgview and highlight dat sheeit
    func textViewDidChange(textView: UITextView) {
        msgCharCount = crumbMessageTextView.text.characters.count
        charLabelCount.text = String(256 - msgCharCount)
        
        if crumbMessageTextView.text.characters.count >= 256 {
            //TODO: highlight >:( number indicating too long
            //will doo soon ------------
            charLabelCount.textColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        }else{
            charLabelCount.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        }
    }
    
    //test msglength
    func msgLengthTest() -> Bool {
        if crumbMessageTextView.text.characters.count >= 257 || crumbMessageTextView.text.characters.count < 1 || crumbMessageTextView.text == "Write your message here. here." {//fixed 256 off by one error; if want to shorten to 128 make sure to set as 129
            //fails to send
            return false
        }
        else{
            //succeeds in test; able to send
            return true
        }
    }
    
    //Placeholder Text for msgview:
    //change text color to black when user begins editing textView and disable post button
    func textViewDidBeginEditing(textView: UITextView) {
        
        //disable save button if editing
        postButtonOutlet.enabled = false
        
        if crumbMessageTextView.textColor == UIColor.lightGrayColor() {
            crumbMessageTextView.text = nil
            crumbMessageTextView.textColor = UIColor.blackColor()
        }
    }
    
    //check valid field, better tests than mine "/
    func postButtonEnabledIfTestsTrue() {
        
        // Disable the Save button if the text field is empty.
        let text = crumbMessageTextView.text ?? ""
        if crumbMessageTextView.text != "Write your message here." && crumbMessageTextView.text.characters.count <= 256 {
            if checkLocation() {
                postButtonOutlet.enabled = !text.isEmpty
            }
            else{
                print("loc is not available")// add a loc indicator somehow; make sure user knows we cant find their loc & it is their fault not apps
            }
        }
    }
    
    //If user didn't edit field return to gray
    func textViewDidEndEditing(textView: UITextView) {
        if crumbMessageTextView.text.isEmpty{
            crumbMessageTextView.text = "Write your message here."
            crumbMessageTextView.textColor = UIColor.lightGrayColor()
        }
        postButtonEnabledIfTestsTrue()
    }
    
    // make sure user doesnt make newlines
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n"{
            textView.resignFirstResponder()
            return false;
        }
        return true
    }
    
    func checkLocation() -> Bool{
        if locationManager.location != nil{
            return true
        } else{
            
            print("location services are down")
            return false
        }
    }
    
    //MARK: Navigation
    
    //cancel writecrumb and return to yourcrumbtableview
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    //Make CrumbMessage and push to iCloud
    @IBAction func postBarButton(sender: AnyObject) {
        addCrumbCDAndCK(sender)
        
    }

}
