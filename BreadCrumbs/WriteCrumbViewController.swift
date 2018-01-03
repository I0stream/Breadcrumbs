
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
import UserNotifications
import SystemConfiguration
import MobileCoreServices

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


class WriteCrumbViewController: UIViewController, UITextViewDelegate, CLLocationManagerDelegate, MIDatePickerDelegate, UNUserNotificationCenterDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    //MARK: Variables
    var msgCharCount:Int = 0
    var timeDroppedvar: String?
    var pickerTimeLimit = [1,2,4,8,12,24,48]
    let NSUserData = AppDelegate().NSUserData
    let locationManager: CLLocationManager = AppDelegate().locationManager
    let helperfunctions = AppDelegate().helperfunctions
    var crumbmessage: CrumbMessage?
    //let managedObjectContext = AppDelegate().getContext() //broke
    var isinfobaropent: Bool?
    //weak var delegate: updateViewDelegate?
    var currentTime: Int?
    
    let datePicker = MIDatePicker.getFromNib()

    
    weak var DeAnimateTimer = Timer()
    
    //MARK: Properties
    
    @IBOutlet weak var pickeroutlet: UIButton!
    @IBOutlet weak var CrumbcounterLabel: UILabel!
    @IBOutlet weak var crumbMessageTextView: UITextView!
    @IBOutlet weak var charLabelCount: UILabel!
    @IBOutlet weak var submitView: UIView!
    @IBOutlet weak var postButtonOutlet: UIButton!
    @IBOutlet weak var CrumbcountExplainerView: UIView!
    
    @IBOutlet weak var ActivIndictatorsss: UIActivityIndicatorView!
    
    @IBOutlet weak var UiViewImageContainer: UIView!
    @IBOutlet weak var imageContainerUIImage: UIImageView!
    var uploadedPhoto: UIImage?
    var photoURL: NSURL?
    var photoAsData: Data?
    
    
    @IBOutlet weak var Greyoutview: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager.startUpdatingLocation()
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation

        datePicker.delegate = self
        // Handle the text field’s user input through delegate callbacks.
        self.crumbMessageTextView.delegate = self
        textViewDidChange(crumbMessageTextView)
        
        //msgView(textView) placeholder text
        crumbMessageTextView.text = "What do you think?"
        crumbMessageTextView.textColor = UIColor.lightGray

        //crumbcount value
        //CrumbcounterLabel.text = "\(NSUserData.string(forKey: "crumbCount")!)/7 Crumbs"
        CrumbcounterLabel.isHidden = true
        
        submitView.isHidden = true
        UiViewImageContainer.isHidden = true
        
        //fuck if I know, post button off unless pass tests
        postButtonEnabledIfTestsTrue()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.hideKeyboardWhenTappedAround()
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
                (granted, error) in
                //Parse errors and track state
            }
            UIApplication.shared.registerForRemoteNotifications()
        }else{
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()

        }
        
        if NSUserData.integer(forKey: "LastPickedTime") == 0{
            currentTime = 48
            pickeroutlet.setTitle("\(currentTime!)h", for: UIControlState())
        }else{
            currentTime = NSUserData.integer(forKey: "LastPickedTime")
            pickeroutlet.setTitle("\(currentTime!)h", for: UIControlState())
        }
        
        //show crumbcount explainer only once; maybe later have a ? mark button to show explainer
        /*if NSUserData.value(forKey: "badgeOther") as! Int == 0{
            //display explainer
            CrumbcountExplainerView.isHidden = false
            
            NSUserData.setValue(1, forKey: "badgeOther")
        }*/
        
        //limit crumbs in area
        if currentReachabilityStatus == .notReachable{//internet down
            animateInfoBar("Internet is unavailable")
            DeAnimateTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(checkToDeAnimate), userInfo: nil, repeats: true)
        }else if checkLocation() {//
            helperfunctions.testStoredMsgsInArea(locationManager.location!)
            if NSUserData.integer(forKey: "limitArea") == 1{
                animateInfoBar("Too many crumbs in area")
            }
        }else if checkLocation() == false{//this is the code i am most proud of, animation is so good
            animateInfoBar("Location is down")
            
            DeAnimateTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(checkToDeAnimate), userInfo: nil, repeats: true)
        }
        
        
        view.addGestureRecognizer(tap)
        
    }

    
    
    //not my code=>
    
    
    
    
    @IBAction func UploadPhotoAction(sender: AnyObject) {
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)){
            if isinfobaropent == true{
                UNanimateInfoBar()
            }
            let picker = UIImagePickerController()
            picker.delegate = self

            
            picker.allowsEditing = false
            picker.sourceType = .photoLibrary
            
            
            picker.modalPresentationStyle = .popover
            present(picker, animated: true, completion: nil)
        }
        else{
            animateInfoBar("No Camera.")

        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        
        let photoPicked = info[UIImagePickerControllerOriginalImage] as! UIImage //2
        photoAsData = UIImageJPEGRepresentation(photoPicked, 0.4)
        var test = NSData(data: photoAsData!)
        
        
        if ((test.length) / 1024) < 1500{
            print("image right size")
            
            let viewit = test.length / 1024
            print(viewit)
            imageContainerUIImage.contentMode = .scaleAspectFit
            imageContainerUIImage.image = photoPicked
            uploadedPhoto = photoPicked
            
            photoURL = writeImage(image:photoPicked)
            
            imageContainerUIImage.layer.cornerRadius = 5.0
            imageContainerUIImage.clipsToBounds = true
            
            UiViewImageContainer.isHidden = false
            
            postButtonEnabledIfTestsTrue()
            
        }else{
            let viewit = test.length / 1024
            print(viewit)
            
            test = NSData(data: UIImageJPEGRepresentation(photoPicked, 0.3)!)
            if ((test.length) / 1024) < 1000{
                
                let viewit = test.length / 1024
                print(viewit)
                
                photoAsData = UIImageJPEGRepresentation(photoPicked, 0.2)

                imageContainerUIImage.contentMode = .scaleAspectFit
                imageContainerUIImage.image = photoPicked
                uploadedPhoto = photoPicked
                
                photoURL = writeImage(image:photoPicked)
                
                imageContainerUIImage.layer.cornerRadius = 5.0
                imageContainerUIImage.clipsToBounds = true
                
                UiViewImageContainer.isHidden = false
                
                postButtonEnabledIfTestsTrue()
            } else{
                animateInfoBar("Image is too large")

                let viewit = test.length / 1024
                print(viewit)
            }

            
        }
        dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    //<=not my code sort of
    
    
    @IBAction func CancelPhotoOnMessage(_ sender: Any) {
        UiViewImageContainer.isHidden = true
        uploadedPhoto = nil
        imageContainerUIImage.image = nil
        photoURL = nil
        photoAsData = nil
        
    }
    

    
    
    
    func miDatePicker(_ amDatePicker: MIDatePicker, didSelect time: Int) {
        // Do something when the user has confirmed a selected date
        currentTime = pickerTimeLimit[time]
        pickeroutlet.setTitle("\(currentTime!)h", for: UIControlState())
    }
    func miDatePicker(_ amDatePicker: MIDatePicker, moveSelect: Void) {}
    
    @IBAction func ShowPicker(_ sender: AnyObject) {
        datePicker.show(inVC: self, row: pickerTimeLimit.index(of: currentTime!)!)
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
    
    
    func saveToCloudThenCD(_ crumbmessage: CrumbMessage?){
        
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
        
        //Photo save, convert to file url
        
        if crumbmessage?.photo != nil{
            
            //include safety here
            let photoasset = CKAsset(fileURL: photoURL! as URL)
            record.setValue(photoasset, forKey: "photoUploaded")
        }
        
        
        
        publicData.save(record, completionHandler: { record, error in
            if error != nil {
                print(error.debugDescription)
                print("ck error in write crumbs")
                
                self.dismiss(animated: true, completion: nil)
            }else{
                crumbmessage?.uRecordID = record?.recordID.recordName
                self.saveToCoreDataWrite(crumbmessage!)
                
            }
        })
    }
    
    
    func writeImage(image: UIImage) -> NSURL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(NSUUID().uuidString + ".jpeg")
        if let imageData = UIImageJPEGRepresentation(image, 0.9) {
            
            do {try imageData.write(to: fileURL, options: .noFileProtection)}//writeToURL(fileURL, atomically: false)
            catch { print("fucked") }
        }
        
        return fileURL as NSURL
    }
    
    func saveToCoreDataWrite(_ crumbmessage: CrumbMessage){//it has to do with threading
        //create Message: NSManagedObject
        DispatchQueue.main.async(execute: { () -> Void in
            if #available(iOS 10.0, *) {
                //guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                //    return
                //}
                //let moc = appDelegate.persistentContainer.viewContext
                let moc = AppDelegate().CDStack.mainContext
                
                let entity = NSEntityDescription.entity(forEntityName: "Message", in: moc)!
                
                let message = Message(entity: entity, insertInto: moc)
                
                message.text = crumbmessage.text
                message.senderName = crumbmessage.senderName
                message.timeDropped = crumbmessage.timeDropped
                message.timeLimit = crumbmessage.timeLimit as NSNumber?
                message.initFromLocation(crumbmessage.location)
                message.senderuuid = crumbmessage.senderuuid
                message.votevalue = crumbmessage.votes as NSNumber?
                message.recorduuid = crumbmessage.uRecordID
                if crumbmessage.photo != nil{
                    message.photo = self.photoAsData!
                }
                do {
                    try message.managedObjectContext?.save()
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "load"), object: nil)//reloads crmessages from cd everywhere
                    //self.delegate?.addNewMessage(crumbmessage)
                    self.dismiss(animated: true, completion: nil)
                    
                    
                } catch {
                    print(error)
                    print("cd error in write crumbs")
                }
                
            }
        })
    }
    override func viewWillDisappear(_ animated: Bool) {
        DeAnimateTimer?.invalidate()
    }
    
    //add crumb to coredata
    func addCrumbCDAndCK(_ sender: AnyObject?) {
        if postButtonOutlet === sender{
            if testMsg() == true && checkLocation() == true && AppDelegate().NSUserData.integer(forKey: "limitArea") == 0 {
                
                var msgText = crumbMessageTextView.text
                if crumbMessageTextView.textColor == UIColor.lightGray{
                    msgText = "   "
                }
                let senderUser = NSUserData.string(forKey: "userName")!
                let senderid = NSUserData.string(forKey: "recordID")!
                CrumbCDCK(text: msgText!, User: senderUser, senderid: senderid, currentime: currentTime!)
            }
        }
    }
    
    func CrumbCDCK(text: String, User: String, senderid: String, currentime: Int){
        if checkLocation() == true{
            
            
            //update crumbcount value, maybe move this to savetocloud
            /*if senderid == NSUserData.string(forKey: "recordID")!{
                let cCounter: Int = Int(NSUserData.string(forKey: "crumbCount")!)! - 1
            
                NSUserData.setValue(cCounter, forKey: "crumbCount")
                AppDelegate().UpdateCrumbCount(cCounter)
            }*/
            
            
            //init date, location for the message obj
            let date = Date()
            let curLoc = locationManager.location!

            
            //create crumbMessage object
            
            crumbmessage = CrumbMessage(text: text, senderName: User, location: curLoc, timeDropped: date, timeLimit: currentime, senderuuid: senderid, votes: 0)
            crumbmessage?.hasVoted = 0//keychain
            
            if uploadedPhoto != nil{
                print("photo uploaded")
                crumbmessage?.photo = uploadedPhoto!
            }else {
                print("no photo")
            }
            
            
            self.NSUserData.setValue(Date(), forKey: "SinceLastCheck")
            self.NSUserData.setValue(currentTime!, forKey: "LastPickedTime")
            
            print(NSUserData.integer(forKey: "crumbCount"))
            //put loading indicator and grey out here
            ActivIndictatorsss.isHidden = false
            Greyoutview.isHidden = false
            //ActivIndictatorsss.startAnimating()
            self.saveToCloudThenCD(self.crumbmessage)//saves both cd and ck
            
            
        } else {
            print("Tests did fail :(")/*I need to add an indicator and disable the post button if the
             tests are failing; like jesus it makes testing shit a pain in my ass whenever I sim it
             the loc services dont auto run half the time and then I have to dick around with it*/
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
        if /*Int(NSUserData.string(forKey: "crumbCount")!) > 0 &&*/ msgLengthTest() || uploadedPhoto != nil{
            
            return true
        } else if msgLengthTest() == false{ //fail case; length is incorrect
            print("Length error")
            return false
            
        } else { //fail case; user has no remaining messages
            
            //alert user they are out of msgs
            
            //let alert = UIAlertController(title: "Error", message: "You are out of crumbs, wait an hour to recieve more", preferredStyle: UIAlertControllerStyle.alert)
            //alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
            //self.present(alert, animated: true, completion: nil)
            print("out of crumbs somehow")
            return false
        }
    }
    
    //test msglength
    func msgLengthTest() -> Bool {
        if crumbMessageTextView.text.count >= 257 || crumbMessageTextView.text.count < 1 || crumbMessageTextView.text == "What do you think?" {//fixed 256 off by one error; if want to shorten to 128 make sure to set as 129
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
        if (crumbMessageTextView.text != "What do you think?" || uploadedPhoto != nil ) && crumbMessageTextView.text.count <= 256 {
            if checkLocation() && currentReachabilityStatus != .notReachable {
                submitView.isHidden = false
                postButtonOutlet.isEnabled = true
            }
        }
    }
    
    //Placeholder Text for msgview:
    //change text color to black when user begins editing textView and disable post button
    func textViewDidBeginEditing(_ textView: UITextView) {
        
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
            
            msgCharCount = crumbMessageTextView.text.count
            charLabelCount.text = String(256 - msgCharCount)
        } else {
            charLabelCount.text = String(256)
        }
        if crumbMessageTextView.text.count >= 256 {
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
            
            if uploadedPhoto == nil{
                submitView.isHidden = true
            }
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
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        self.NSUserData.setValue(currentTime!, forKey: "LastPickedTime")
    }
    @IBAction func PostMessage(_ sender: AnyObject) {
        addCrumbCDAndCK(sender)
        postButtonOutlet.isEnabled = false
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }
}

/*extension WriteCrumbViewController{

}*/
extension WriteCrumbViewController{//MARK: Alarm info bar
    //MARK: timer
    func checkToDeAnimate(){
        if checkLocation() == true{
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            UNanimateInfoBar()
            DeAnimateTimer?.invalidate()
        }
    }
    
    //MARK: Subview
    
    func animateInfoBar(_ alert: String){
        let duration = 0.5
        let delay = 0.5
        let options = UIViewAnimationOptions.transitionCurlDown
        let damping:CGFloat = 1 // set damping ration
        let velocity:CGFloat = 1.0
        
        isinfobaropent = true
        
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
        
        isinfobaropent = false
        
        UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: options, animations: {
            self.removeInfoBarView()
        }) { (true) in
            self.view.viewWithTag(5)!.removeFromSuperview()
            
        }
        //makeSubViewIndicator("Location is down")
        
        
    }
    
    func makeSubViewIndicator(_ text: String){
        view.viewWithTag(2)?.transform.ty = (view.viewWithTag(2)?.transform.ty)! + 20
        view.viewWithTag(143)?.transform.ty = (view.viewWithTag(143)?.transform.ty)! + 20
        view.viewWithTag(26)?.transform.ty = (view.viewWithTag(26)?.transform.ty)! + 20
        
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
        self.view.viewWithTag(5)!.frame = CGRect(x: 0, y:(self.view.viewWithTag(1)!.frame.size.height), width: (view.frame.size.width), height: 0)
        self.view.viewWithTag(26)?.transform.ty = (view.viewWithTag(26
            )?.transform.ty)! - 20//text
        view.viewWithTag(143)?.transform.ty = (view.viewWithTag(143)?.transform.ty)! - 20//textbox
        view.viewWithTag(2)?.transform.ty = (view.viewWithTag(2)?.transform.ty)! - 20
        
        self.view.viewWithTag(4)!.removeFromSuperview()
    }
}
