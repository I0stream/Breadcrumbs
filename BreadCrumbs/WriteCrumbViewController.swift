
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

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class WriteCrumbViewController: UIViewController, UITextViewDelegate, CLLocationManagerDelegate, MIDatePickerDelegate{
    
    //MARK: Variables
    var msgCharCount:Int = 0
    var timeDroppedvar: String?
    var pickerTimeLimit = [4,8,12,24,48]
    let NSUserData = AppDelegate().NSUserData
    let locationManager: CLLocationManager = AppDelegate().locationManager
    let helperfunctions = Helper()
    var crumbmessage: CrumbMessage?
    //let managedObjectContext = AppDelegate().getContext() //broke

    var currentTime = 4
    
    let datePicker = MIDatePicker.getFromNib()

    
    weak var timer = Timer()
    
    //MARK: Properties
    
    @IBOutlet weak var pickeroutlet: UIButton!
    @IBOutlet weak var CrumbcounterLabel: UILabel!
    @IBOutlet weak var crumbMessageTextView: UITextView!
    @IBOutlet weak var charLabelCount: UILabel!
    @IBOutlet weak var submitView: UIView!
    @IBOutlet weak var postButtonOutlet: UIButton!
    @IBOutlet weak var CrumbcountExplainerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        datePicker.delegate = self
        // Handle the text field’s user input through delegate callbacks.
        self.crumbMessageTextView.delegate = self
        textViewDidChange(crumbMessageTextView)
        //msgView(textView) placeholder text
        crumbMessageTextView.text = "What do you think?"
        crumbMessageTextView.textColor = UIColor.lightGray
        
        //crumbcount value
        CrumbcounterLabel.text = "\(NSUserData.string(forKey: "crumbCount")!)/7 crumbs"
        
        submitView.isHidden = true
        
        //fuck if I know, post button off unless pass tests
        postButtonEnabledIfTestsTrue()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.hideKeyboardWhenTappedAround()
        
        //show crumbcount explainer only once; maybe later have a ? mark button to show explainer
        if NSUserData.integer(forKey: "ExplainerCrumb") == 0{
            //display explainer
            CrumbcountExplainerView.isHidden = true
            
            NSUserData.set(1, forKey: "ExplainerCrumb")
        }
        
        
        
        //start load and store if not already
        if !(AppDelegate().timer1 == nil) && !(checkLocation()) {
            print("running in write")
            Timer.scheduledTimer(timeInterval: 60.0, target: AppDelegate(), selector: #selector(AppDelegate().loadAndStoreiCloudMsgsBasedOnLoc), userInfo: nil, repeats: true)//checks icloud every 30 sec for a msg
        }
        
        //limit crumbs in area
        if checkLocation(){//
            helperfunctions.testStoredMsgsInArea(locationManager.location!)
            
            if NSUserData.integer(forKey: "limitArea") == 1{
                animateInfoBar("Too many crumbs in area")
            }
        }
        if checkLocation() == false{//this is the code i am most proud of, animation is so good
            animateInfoBar("Location is down")
            
            timer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(checkToDeAnimate), userInfo: nil, repeats: true)
        }
        view.addGestureRecognizer(tap)
    }

    func miDatePicker(_ amDatePicker: MIDatePicker, didSelect time: Int) {
        // Do something when the user has confirmed a selected date
        currentTime = pickerTimeLimit[time]
        pickeroutlet.setTitle("\(currentTime) hours", for: UIControlState())
        print(currentTime)
    }
    func miDatePicker(_ amDatePicker: MIDatePicker, moveSelect: Void) {
    }


    func numberOfComponentsInPickerView(_ pickerView: UIPickerView) -> Int {
     return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return datePicker.config.times.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return datePicker.config.times[row]
    }
    
    @IBAction func ShowPicker(_ sender: AnyObject) {
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
    
    func animateInfoBar(_ alert: String){
        let duration = 0.5
        let delay = 0.5
        let options = UIViewAnimationOptions.transitionCurlDown
        let damping:CGFloat = 1 // set damping ration
        let velocity:CGFloat = 1.0
        self.makeSubViewIndicator(alert)
        UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: options, animations: {
            self.view.viewWithTag(5)!.frame = CGRect(x: 0, y:((self.view.viewWithTag(1)!.frame.size.height)), width: (self.view.frame.size.width), height: 20)
            
        }) { (true) in
        }
        //makeSubViewIndicator("Location is down")
    }
    func UNanimateInfoBar(){
        let duration = 1.0
        let delay = 0.0
        let options = UIViewAnimationOptions.transitionCurlUp
        let damping:CGFloat = 1 // set damping ration
        let velocity:CGFloat = 1.0
        
        UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: options, animations: {
            self.removeInfoBarView()
        }) { (true) in
            self.view.viewWithTag(5)!.removeFromSuperview()
            
        }
        //makeSubViewIndicator("Location is down")
        
    }
    
    func makeSubViewIndicator(_ text: String){
        view.viewWithTag(2)?.transform.ty = (view.viewWithTag(2)?.transform.ty)! + 20
        view.viewWithTag(34)?.transform.ty = (view.viewWithTag(34)?.transform.ty)! + 20

        let labelAnimate = UITextField(frame: CGRect(x: 0, y:((self.view.viewWithTag(1)!.frame.size.height)), width: (view.frame.size.width), height: 20))
        labelAnimate.isUserInteractionEnabled = false
        labelAnimate.text = text
        labelAnimate.textColor = UIColor.white
        labelAnimate.textAlignment = NSTextAlignment.center
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
            view.viewWithTag(34)?.transform.ty = (view.viewWithTag(34)?.transform.ty)! - 20
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
    
    func UpdateCrumbCount(_ cCount: Int){
        
        let recordID = NSUserData.string(forKey: "recordID")!
        
        let specificID = CKRecordID(recordName: "\(recordID)")
        
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        
        
        publicData.fetch(withRecordID: specificID, completionHandler: {record, error in
            if error == nil{
                record!.setObject(cCount as CKRecordValue?, forKey: "crumbCount")
                //print("updated crumbcount, check cloud database")
                
                publicData.save(record!, completionHandler: {theRecord, error in
                    if error == nil{
                        print("saved version")
                    }else{
                        print(error as Any)
                    }
                })
            }else{
                print("error")
            }
        })
        
    }
    
    func saveToCloud(_ crumbmessage: CrumbMessage?){
        
        //upload to iCloud
        
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        
        let record = CKRecord(recordType: "CrumbMessage")
        
        record.setValue(crumbmessage?.location, forKey: "location")
        record.setValue(crumbmessage?.senderName, forKey: "senderName")
        record.setValue(crumbmessage?.text, forKey: "text")
        record.setValue(crumbmessage?.timeDropped, forKey: "timeDropped")
        record.setValue(crumbmessage?.timeLimit, forKey: "timeLimit")
        record.setValue(crumbmessage?.senderuuid, forKey: "senderuuid")
        record.setValue(crumbmessage?.votes, forKey: "votes")
        
        publicData.save(record, completionHandler: { record, error in
            if error != nil {
                print(error.debugDescription)
                print("ck error in write crumbs")
            }else{
                crumbmessage?.uRecordID = record?.recordID.recordName
                self.saveToCoreData(crumbmessage!)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "load"), object: nil)
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    func saveToCoreData(_ crumbmessage: CrumbMessage){
        //create Message: NSManagedObject
        if #available(iOS 10.0, *) {
            
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            
            let moc = appDelegate.persistentContainer.viewContext
            
            let entity = NSEntityDescription.entity(forEntityName: "Message", in: moc)
            let message = Message(entity: entity!, insertInto: moc)
            
            /*message.setValue(crumbmessage.text, forKeyPath: "text")
            message.setValue(crumbmessage.senderName, forKeyPath: "senderName")
            message.setValue(crumbmessage.timeDropped, forKeyPath: "timeDropped")
            message.setValue(crumbmessage.timeLimit as NSNumber?, forKey: "timeLimit")
            message.
            message.setValue(crumbmessage.senderuuid, forKeyPath: "senderuuid")
            message.setValue(crumbmessage.votes as NSNumber?, forKeyPath: "votevalue")
            message.setValue(crumbmessage.uRecordID, forKeyPath: "recorduuid")*/

            
            message.text = crumbmessage.text
            message.senderName = crumbmessage.senderName
            message.timeDropped = crumbmessage.timeDropped
            message.timeLimit = crumbmessage.timeLimit as NSNumber?
            message.initFromLocation(crumbmessage.location)
            message.senderuuid = crumbmessage.senderuuid
            message.votevalue = crumbmessage.votes as NSNumber?
            message.recorduuid = crumbmessage.uRecordID
            do {
                try message.managedObjectContext?.save()
                //print("saved to coredata")
            } catch {
                print(error)
                print("cd error in write crumbs")
                
            }
        }else{
            let message = NSEntityDescription.insertNewObject(forEntityName: "Message", into: AppDelegate().managedObjectContext) as! BreadCrumbs.Message
        
            message.setValue(crumbmessage.text, forKey: "text")
            message.setValue(crumbmessage.senderName, forKey: "senderName")
            message.setValue(crumbmessage.timeDropped, forKey: "timeDropped")
            message.setValue(crumbmessage.timeLimit, forKey: "timeLimit")
            message.initFromLocation(crumbmessage.location)
            message.setValue(crumbmessage.senderuuid, forKey: "senderuuid")
            message.setValue(crumbmessage.votes, forKey: "votevalue")
            message.setValue(crumbmessage.uRecordID, forKey: "recorduuid")
        //messageMO.setValue(crumbmessage.addressStr, forKey: "addressStr")
            do {
                try message.managedObjectContext?.save()
                //print("saved to coredata")
            } catch {
                print(error)
                print("cd error in write crumbs")
                
            }
        }
        
    }
    
    //add crumb to coredata
    func addCrumbCDAndCK(_ sender: AnyObject?) {
        if postButtonOutlet === sender{
            if testMsg() == true && checkLocation() == true && AppDelegate().NSUserData.integer(forKey: "limitArea") == 0 {
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                
                let cCounter: Int = Int(NSUserData.string(forKey: "crumbCount")!)! - 1
                //print(cCounter)
                
                NSUserData.setValue(cCounter, forKey: "crumbCount")
                self.UpdateCrumbCount(cCounter)
                
                let senderUser = NSUserData.string(forKey: "userName")!
                let date = Date()

                
                //create crumbMessage object
                crumbmessage = CrumbMessage(text: crumbMessageTextView.text, senderName: senderUser, location: locationManager.location!, timeDropped: date, timeLimit: currentTime, senderuuid: NSUserData.string(forKey: "recordID")!, votes: 0)
                
                self.saveToCloud(self.crumbmessage)//saves both cd and ck
                
                self.NSUserData.setValue(Date(), forKey: "SinceLastCheck")
                //NotificationCenter.default.post(name: Notification.Name(rawValue: "load"), object: nil)
                //self.dismiss(animated: true, completion: nil)
                
                // })//NEED ERROR HANDLING HERE KEK yeah right dec 10
                
                
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
        if Int(NSUserData.string(forKey: "crumbCount")!) > 0 && msgLengthTest(){
            
            return true
        } else if msgLengthTest() == false{ //fail case; length is incorrect
            print("Length error")
            return false
            
        } else { //fail case; user has no remaining messages
            
            //alert user they are out of msgs
            
            let alert = UIAlertController(title: "Error", message: "You are out of crumbs, wait X more minutes to receive more", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
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
                submitView.isHidden = false
                postButtonOutlet.isEnabled = true
            }
        }
    }
    
    //Placeholder Text for msgview:
    //change text color to black when user begins editing textView and disable post button
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        //disable save button if editing
        //postButtonOutlet.enabled = false
        
        if crumbMessageTextView.textColor == UIColor.lightGray {
            crumbMessageTextView.text = nil
            crumbMessageTextView.textColor = UIColor.black
        }
    }
    
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        postButtonEnabledIfTestsTrue()
    }
    //track chars in msgview and highlight dat sheeit
    func textViewDidChange(_ textView: UITextView) {
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
    func textViewDidEndEditing(_ textView: UITextView) {
        if crumbMessageTextView.text.isEmpty{
            crumbMessageTextView.text = "What do you think?"
            crumbMessageTextView.textColor = UIColor.lightGray
            submitView.isHidden = true
        }
    }
    
    // make sure user doesnt make newlines
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n"{
            textView.resignFirstResponder()
            return false;
        }
        return true
    }
    
    
    //MARK: Navigation
    //cancel writecrumb and return to yourcrumbtableview
    @IBAction func CancelPost(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func PostMessage(_ sender: AnyObject) {
        addCrumbCDAndCK(sender)
    }
    //Make CrumbMessage and push to iCloud
    /*    @IBAction func postBarButton(sender: AnyObject) {
     
     }
     */
}
