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
    
        var comment: CommentShort?
        var viewbreadcrumb: CrumbMessage?
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.WriteReportTextView.delegate = self
            textViewDidChange(WriteReportTextView)
            //msgView(textView) placeholder text
            WriteReportTextView.text = "What do you think?"
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
            if WriteReportTextView.text.characters.count >= 126 || WriteReportTextView.text.characters.count < 2 || WriteReportTextView.text == "What do you think?" {//fixed 256 off by one error; if want to shorten to 128 make sure to set as 129
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
            if WriteReportTextView.text != "What do you think?" && WriteReportTextView.text.characters.count <= 126 {
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
            if WriteReportTextView.text != "What do you think?"{
                let msgCharCount = WriteReportTextView.text.characters.count
                charCount.text = String(126 - msgCharCount)
            }else {
                charCount.text = String(126)
            }
            if WriteReportTextView.text.characters.count >= 126 {
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
                WriteReportTextView.text = "What do you think?"
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

            //AddToCD(newComment)
            ReportToCK()
        }
        func ReportToCK(){//need to know reference of crumb
            //upload to iCloud
            
            let container = CKContainer.default()
            let publicData = container.publicCloudDatabase
            
            let commentRecord = CKRecord(recordType: "Comment")
            
            commentRecord.setValue(comment?.timeSent, forKey: "timeSent")
            
            //var ref = CKReference(record: listRecord, action: .DeleteSelf)
            //itemRecord.setObject(ref, forKey: "owningList")
            
            let recordid = CKRecordID(recordName: (viewbreadcrumb?.uRecordID)!)
            let reference = CKReference(recordID: recordid, action: CKReferenceAction.deleteSelf)
            
            commentRecord.setValue(reference, forKey: "ownerReference")//should be right but might not be
            
            //print("dis after zone")
            //print(viewbreadcrumb?.uRecordID as Any)
            
            publicData.save(commentRecord, completionHandler: { record, error in
                if error == nil {

                }else if error != nil {
                    print(error.debugDescription)
                    print("ck error in create comment")
                }
            })
        }
    
        
        @IBAction func CancelReport(_ sender: AnyObject) {
            dismiss(animated: true, completion: nil)
        }
        
        @IBAction func submitReport(_ sender: AnyObject) {
            Report()
            dismiss(animated: true, completion: nil)
            
        }
    }
