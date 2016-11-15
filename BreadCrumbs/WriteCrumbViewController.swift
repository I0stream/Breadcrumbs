
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

class WriteCrumbViewController: UIViewController, UITextViewDelegate, CLLocationManagerDelegate, MIDatePickerDelegate{
    
    //MARK: Variables
    var msgCharCount:Int = 0
    var timeDroppedvar: String?
    var pickerTimeLimit = [4,8,12,24,48]
    let NSUserData = AppDelegate().NSUserData
    let locationManager: CLLocationManager = AppDelegate().locationManager
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext //yay
    let helperfunctions = Helper()
    var crumbmessage: CrumbMessage?
    
    var currentTime = 4
    
    let datePicker = MIDatePicker.getFromNib()

    
    weak var timer = NSTimer()
    
    //MARK: Properties
    
    @IBOutlet weak var pickeroutlet: UIButton!
    //@IBOutlet weak var msgTimePickerField: UIPickerView!
    
    
    //@IBOutlet weak var TimePicker: MIDatePicker!
    
    //@IBOutlet weak var barCrumbCounterNumber: UIBarButtonItem!
    @IBOutlet weak var crumbMessageTextView: UITextView!
    @IBOutlet weak var charLabelCount: UILabel!
    
    @IBOutlet weak var submitView: UIView!
    @IBOutlet weak var postButtonOutlet: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        datePicker.delegate = self
        
        // Handle the text field’s user input through delegate callbacks.
        self.crumbMessageTextView.delegate = self
        textViewDidChange(crumbMessageTextView)
        //msgView(textView) placeholder text
        crumbMessageTextView.text = "What do you think?"
        crumbMessageTextView.textColor = UIColor.lightGrayColor()
        
        //init pickerview
        //self.msgTimePickerField.dataSource = self
        //self.msgTimePickerField.delegate = self
        //msgTimePickerField.hidden = true
        
        //populate crumb counter number
        //barCrumbCounterNumber.title = "\(NSUserData.stringForKey("crumbCount")!)/5"
        
        submitView.hidden = true
        
        //fuck if I know, post button off unless pass tests
        postButtonEnabledIfTestsTrue()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.hideKeyboardWhenTappedAround()
        
        if !(AppDelegate().timer1 == nil) && !(checkLocation()) {
            print("running in write")
            NSTimer.scheduledTimerWithTimeInterval(60.0, target: AppDelegate(), selector: #selector(AppDelegate().loadAndStoreiCloudMsgsBasedOnLoc), userInfo: nil, repeats: true)//checks icloud every 30 sec for a msg
        }
        
        if checkLocation(){//
            helperfunctions.testStoredMsgsInArea(locationManager.location!)
            
            if NSUserData.integerForKey("limitArea") == 1{
                animateInfoBar("Too many crumbs in area")
            }
        }
        if checkLocation() == false{//this is the code i am most proud of, animation is so good
            animateInfoBar("Location is down")
            
            timer = NSTimer.scheduledTimerWithTimeInterval(10.0, target: self, selector: #selector(checkToDeAnimate), userInfo: nil, repeats: true)
        }
        view.addGestureRecognizer(tap)
    }
    func miDatePicker(amDatePicker: MIDatePicker, didSelect time: Int) {
        // Do something when the user has confirmed a selected date
        currentTime = pickerTimeLimit[time]
        pickeroutlet.setTitle("\(currentTime) hours", forState: .Normal)
        print(currentTime)
    }
    func miDatePickerDidCancelSelection(amDatePicker: MIDatePicker) {
        // Do something then user tapped the cancel button
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
     return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return datePicker.config.times.count
    }
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return datePicker.config.times[row]
    }
    
    @IBAction func ShowPicker(sender: AnyObject) {
        datePicker.show(inVC: self)
    }
    //MARK: timer
    func checkToDeAnimate(){
        if checkLocation() == true{
            UNanimateInfoBar()
            timer?.invalidate()
        }
    }
    
    //MARK: Subview
    
    func animateInfoBar(alert: String){
        let duration = 0.5
        let delay = 0.5
        let options = UIViewAnimationOptions.TransitionCurlDown
        let damping:CGFloat = 1 // set damping ration
        let velocity:CGFloat = 1.0
        self.makeSubViewIndicator(alert)
        UIView.animateWithDuration(duration, delay: delay, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: options, animations: {
            self.view.viewWithTag(5)!.frame = CGRect(x: 0, y:((self.view.viewWithTag(1)!.frame.size.height)), width: (self.view.frame.size.width), height: 20)
            
        }) { (true) in
        }
        //makeSubViewIndicator("Location is down")
    }
    func UNanimateInfoBar(){
        let duration = 1.0
        let delay = 0.0
        let options = UIViewAnimationOptions.TransitionCurlUp
        let damping:CGFloat = 1 // set damping ration
        let velocity:CGFloat = 1.0
        
        UIView.animateWithDuration(duration, delay: delay, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: options, animations: {
            self.removeInfoBarView()
        }) { (true) in
            self.view.viewWithTag(5)!.removeFromSuperview()
            
        }
        //makeSubViewIndicator("Location is down")
        
    }
    
    func makeSubViewIndicator(text: String){
        view.viewWithTag(2)?.transform.ty = (view.viewWithTag(2)?.transform.ty)! + 20
        let labelAnimate = UITextField(frame: CGRect(x: 0, y:((self.view.viewWithTag(1)!.frame.size.height)), width: (view.frame.size.width), height: 20))
        labelAnimate.userInteractionEnabled = false
        labelAnimate.text = text
        labelAnimate.textColor = UIColor.whiteColor()
        labelAnimate.textAlignment = NSTextAlignment.Center
        labelAnimate.tag = 4
        
        //rectangle
        let backgroundrect = UIView()
        backgroundrect.frame = CGRect(x: 0, y:((self.view.viewWithTag(1)!.frame.size.height)), width: (view.frame.size.width), height: 20)
        backgroundrect.backgroundColor = UIColor(red: 90/255, green: 174/255, blue: 255/255, alpha: 1)
        
        backgroundrect.tag = 5
        
        view.addSubview(backgroundrect)
        view.addSubview(labelAnimate)
    }
    func removeInfoBarView(){
        self.view.viewWithTag(5)!.frame = CGRect(x: 0, y:((self.navigationController?.navigationBar.frame.size.height)!), width: (view.frame.size.width), height: 0)
        
        for subview in view.subviews{
            if let stackview = subview as? UIStackView{
                stackview.transform.ty = stackview.transform.ty - 20
            }
            if let label = subview as? UILabel{
                label.transform.ty = label.transform.ty - 20
            }
        }
        self.view.viewWithTag(4)!.removeFromSuperview()
    }
    
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(WriteCrumbViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
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
                print("ck error in write crumbs")
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
        //messageMO.setValue(crumbmessage.addressStr, forKey: "addressStr")
        
        
        do {
            try messageMO.managedObjectContext?.save()
            //print("saved to coredata")
        } catch {
            print(error)
            print("cd error in write crumbs")
            
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
                
                //barCrumbCounterNumber.title = "\(NSUserData.stringForKey("crumbCount")!)/5"
                
                let senderUser = NSUserData.stringForKey("userName")!
                let date = NSDate()

                
                //create crumbMessage object
                crumbmessage = CrumbMessage(text: crumbMessageTextView.text, senderName: senderUser, location: locationManager.location!, timeDropped: date, timeLimit: currentTime, senderuuid: NSUserData.stringForKey("recordID")!, votes: 1)
                
                //crumbmessage!.convertCoordinatesToAddress((crumbmessage!.location), completion: { (answer) in
                //self.crumbmessage!.addressStr = answer!
                
                self.saveToCoreData(self.crumbmessage!)
                self.saveToCloud(self.crumbmessage)//saves without msg
                
                self.NSUserData.setValue(NSDate(), forKey: "SinceLastCheck")
                NSNotificationCenter.defaultCenter().postNotificationName("load", object: nil)
                self.dismissViewControllerAnimated(true, completion: nil)
                
                // })//NEED ERROR HANDLING HERE
                
                
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
    
    //test msglength
    func msgLengthTest() -> Bool {
        if crumbMessageTextView.text.characters.count >= 257 || crumbMessageTextView.text.characters.count < 1 || crumbMessageTextView.text == "What do you think?" {//fixed 256 off by one error; if want to shorten to 128 make sure to set as 129
            //fails to send
            return false
        }
        else{
            //succeeds in test; able to send
            return true
        }
    }
    func checkLocation() -> Bool{
        if locationManager.location != nil{
            return true
        } else{
            return false
        }
    }
    //check valid field, better tests than mine "/
    func postButtonEnabledIfTestsTrue() {
        
        // Disable the Save button if the text field is empty.
        //let text = crumbMessageTextView.text ?? ""
        if crumbMessageTextView.text != "What do you think?" && crumbMessageTextView.text.characters.count <= 256 {
            if checkLocation() {
                submitView.hidden = false
                postButtonOutlet.enabled = true
            }
        }
    }
    
    //Placeholder Text for msgview:
    //change text color to black when user begins editing textView and disable post button
    func textViewDidBeginEditing(textView: UITextView) {
        
        //disable save button if editing
        //postButtonOutlet.enabled = false
        
        if crumbMessageTextView.textColor == UIColor.lightGrayColor() {
            crumbMessageTextView.text = nil
            crumbMessageTextView.textColor = UIColor.blackColor()
        }
    }
    
    
    func textViewDidChangeSelection(textView: UITextView) {
        postButtonEnabledIfTestsTrue()
    }
    //track chars in msgview and highlight dat sheeit
    func textViewDidChange(textView: UITextView) {
        if crumbMessageTextView.text != "What do you think?"{
            msgCharCount = crumbMessageTextView.text.characters.count
            charLabelCount.text = String(256 - msgCharCount)
        } else {
            charLabelCount.text = String(256)
        }
        if crumbMessageTextView.text.characters.count >= 256 {
            //TODO: highlight >:( number indicating too long
            //will doo soon ------------
            charLabelCount.textColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        }else{
            charLabelCount.textColor = UIColor(red: 162/255, green: 162/255, blue: 162/255, alpha: 1)
        }
    }
    //If user didn't edit field return to gray
    func textViewDidEndEditing(textView: UITextView) {
        if crumbMessageTextView.text.isEmpty{
            crumbMessageTextView.text = "What do you think?"
            crumbMessageTextView.textColor = UIColor.lightGrayColor()
            submitView.hidden = true
        }
    }
    
    // make sure user doesnt make newlines
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n"{
            textView.resignFirstResponder()
            return false;
        }
        return true
    }
    
    
    //MARK: Navigation
    //cancel writecrumb and return to yourcrumbtableview
    @IBAction func CancelPost(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    @IBAction func PostMessage(sender: AnyObject) {
        addCrumbCDAndCK(sender)
    }
    //Make CrumbMessage and push to iCloud
    /*    @IBAction func postBarButton(sender: AnyObject) {
     
     }
     */
}
