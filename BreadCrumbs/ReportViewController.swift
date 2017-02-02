//
//  ReportViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 1/25/17.
//  Copyright © 2017 Daniel Schliesing. All rights reserved.
//
import CloudKit
import CoreData
import UIKit


class ReportViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var WriteReportTextView: UITextView!
    @IBOutlet weak var charCount: UILabel!
    
    @IBOutlet weak var submitView: UIView!
    let NSUserData = AppDelegate().NSUserData
    let userSelf = AppDelegate().NSUserData.string(forKey: "recordID")
    
    var reportedMessageId: String?//can be comment or crumbmessage
    var reportedtext: String?
    var reporteduserID: String?
    var reportType: String?
    
    let helperFunctions = Helper()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.WriteReportTextView.delegate = self
        textViewDidChange(WriteReportTextView)
        //msgView(textView) placeholder text
        WriteReportTextView.text = "How did this break our guidelines?"
        WriteReportTextView.textColor = UIColor.lightGray
        charCount.textColor = UIColor.lightGray
        
        submitView.isHidden = true
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.hideKeyboardWhenTappedAround()
        view.addGestureRecognizer(tap)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //test msglength
    func msgLengthTest() -> Bool {
        if WriteReportTextView.text.characters.count >= 256 || WriteReportTextView.text.characters.count < 2 || WriteReportTextView.text == "How did this break our guidelines?" {//fixed 256 off by one error; if want to shorten to 128 make sure to set as 129
            //fails to send
            return false
        }
        else{
            //succeeds in test; able to send
            return true
        }
    }
    
    //check valid field, better tests than mine "/
    func postButtonEnabledIfTestsTrue() {
        
        // Disable the Save button if the text field is empty.
        //let text = WriteCommentTextView.text ?? ""
        if WriteReportTextView.text != "How did this break our guidelines?" && WriteReportTextView.text.characters.count <= 256 {
            submitView.isHidden = false
            //bool.enabled = !text.isEmpty
        }
    }
    
    //Placeholder Text for msgview:
    //change text color to black when user begins editing textView and disable post button
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        //disable save button if editing
        //postButtonOutlet.enabled = false
        
        if WriteReportTextView.textColor == UIColor.lightGray {
            WriteReportTextView.text = nil
            WriteReportTextView.textColor = UIColor.black
        }
    }
    
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        postButtonEnabledIfTestsTrue()
    }
    //track chars in msgview and highlight dat sheeit
    func textViewDidChange(_ textView: UITextView) {
        if WriteReportTextView.text != "How did this break our guidelines?"{
            let msgCharCount = WriteReportTextView.text.characters.count
            charCount.text = String(256 - msgCharCount)
        }else {
            charCount.text = String(256)
        }
        if WriteReportTextView.text.characters.count >= 256 {
            //TODO: highlight >:( number indicating too long
            //will doo soon ------------
            charCount.textColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        }else{
            charCount.textColor = UIColor(red: 162/255, green: 162/255, blue: 162/255, alpha: 1)
        }
    }
    //If user didn't edit field return to gray
    func textViewDidEndEditing(_ textView: UITextView) {
        if WriteReportTextView.text.isEmpty{
            submitView.isHidden = true
            WriteReportTextView.text = "How did this break our guidelines?"
            WriteReportTextView.textColor = UIColor.lightGray
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
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CreateCommentViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    
    func Report(){
        
        if reportType == "crumbmessage"{
            print("crumb")

           helperFunctions.markForDelete(id: reportedMessageId!)
        
            NotificationCenter.default.post(name: Notification.Name(rawValue: "load"), object: nil)//reloads crmessages from cd everywhere
        }else if reportType == "comment"{
            helperFunctions.commentHide(id: reportedMessageId!)
            print("comment")
        }
        //AddToCD(newComment)
        ReportToCK()
    }
    func ReportToCK(){//need to know reference of crumb
        //upload to iCloud
        
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        
        let reportRecord = CKRecord(recordType: "Report")
        
        //var ref = CKReference(record: listRecord, action: .DeleteSelf)
        //itemRecord.setObject(ref, forKey: "owningList")
        
        
        reportRecord.setValue(reportedMessageId, forKey: "reportedMessageID")//message reported
        reportRecord.setValue(userSelf, forKey: "reportSender")//person who sent report
        reportRecord.setValue(WriteReportTextView.text, forKey: "reportText")//why they reported it
        reportRecord.setValue(reporteduserID, forKey: "reportedMessageUserID")
        reportRecord.setValue(Date(), forKey: "whenReported")
        reportRecord.setValue(reportedtext, forKey: "reportedMessageText")

        /*

        let dbreportedMessageUserID = ckreport["reportedMessageUserID"] as! String
        let dbwhenReported = ckreport["whenReported"] as! Date
        let dbreportedMessageText = ckreport["reportedMessageText"] as! String*/
        
        
        publicData.save(reportRecord, completionHandler: { record, error in
            if error == nil {
                
            }else if error != nil {
                print(error.debugDescription)
                print("ck error in report view controller")
            }
        })
    }
    
    
    @IBAction func CancelReport(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submitReport(_ sender: AnyObject) {
        Report()
        performSegue(withIdentifier: "UnwindAllTheWay", sender: self)
        
    }
}
