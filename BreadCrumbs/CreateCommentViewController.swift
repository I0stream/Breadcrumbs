//
//  CreateCommentViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 11/8/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//
import CloudKit
import CoreData
import UIKit

class CreateCommentViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var WriteCommentTextView: UITextView!
    @IBOutlet weak var charCount: UILabel!
    
    @IBOutlet weak var submitView: UIView!
    let NSUserData = AppDelegate().NSUserData
    
    var viewbreadcrumb: CrumbMessage?
    
    weak var delegate: CreateCommentDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.WriteCommentTextView.delegate = self
        textViewDidChange(WriteCommentTextView)
        //msgView(textView) placeholder text
        WriteCommentTextView.text = "What do you think?"
        WriteCommentTextView.textColor = UIColor.lightGray
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
        if WriteCommentTextView.text.count >= 126 || WriteCommentTextView.text.count < 2 || WriteCommentTextView.text == "What do you think?" {//fixed 256 off by one error; if want to shorten to 128 make sure to set as 129
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
        if WriteCommentTextView.text != "What do you think?" && WriteCommentTextView.text.count <= 126 {
            submitView.isHidden = false
            //bool.enabled = !text.isEmpty
        }
    }
    
    //Placeholder Text for msgview:
    //change text color to black when user begins editing textView and disable post button
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        //disable save button if editing
        //postButtonOutlet.enabled = false
        
        if WriteCommentTextView.textColor == UIColor.lightGray {
            WriteCommentTextView.text = nil
            WriteCommentTextView.textColor = UIColor.black
        }
    }
    
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        postButtonEnabledIfTestsTrue()
    }
    //track chars in msgview and highlight dat sheeit
    func textViewDidChange(_ textView: UITextView) {
        if WriteCommentTextView.text != "What do you think?"{
            let msgCharCount = WriteCommentTextView.text.count
            charCount.text = String(126 - msgCharCount)
        }else {
            charCount.text = String(126)
        }
        if WriteCommentTextView.text.count >= 126 {
            //TODO: highlight >:( number indicating too long
            //will doo soon ------------
            charCount.textColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        }else{
            charCount.textColor = UIColor(red: 162/255, green: 162/255, blue: 162/255, alpha: 1)
        }
    }
    //If user didn't edit field return to gray
    func textViewDidEndEditing(_ textView: UITextView) {
        if WriteCommentTextView.text.isEmpty{
            submitView.isHidden = true
            WriteCommentTextView.text = "What do you think?"
            WriteCommentTextView.textColor = UIColor.lightGray
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
    
    
    func AddComment(){
        let date = Date()
        let newComment = CommentShort(username: NSUserData.string(forKey: "userName")!, text: WriteCommentTextView.text, timeSent: date, userID: self.NSUserData.string(forKey: "recordID")!)
        delegate?.addNewComment(newComment)
        //AddToCD(newComment)
        AddToCKThenCD(newComment)
    }
    func AddToCKThenCD(_ comment: CommentShort){//need to know reference of crumb
        //upload to iCloud
        
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        
        let commentRecord = CKRecord(recordType: "Comment")
        
        commentRecord.setValue(comment.timeSent, forKey: "timeSent")
        commentRecord.setValue(comment.username, forKey: "userName")
        commentRecord.setValue(comment.text, forKey: "text")
        commentRecord.setValue(comment.userID, forKey: "senderuuid")
        commentRecord.setValue(viewbreadcrumb?.senderuuid, forKey: "ownerID")
        
        //var ref = CKReference(record: listRecord, action: .DeleteSelf)
        //itemRecord.setObject(ref, forKey: "owningList")
        
        let recordid = CKRecordID(recordName: (viewbreadcrumb?.uRecordID)!)
        let reference = CKReference(recordID: recordid, action: CKReferenceAction.deleteSelf)
        
        commentRecord.setValue(reference, forKey: "ownerReference")//should be right but might not be
        
        //print("dis after zone")
        //print(viewbreadcrumb?.uRecordID as Any)
        
        publicData.save(commentRecord, completionHandler: { record, error in
            if error == nil {
                self.AddToCD(comment, recorduuid: commentRecord
                    .recordID.recordName)
            }else if error != nil {
                print(error.debugDescription)
                print("ck error in create comment")
            }
        })
    }
    
    func AddToCD(_ comment: CommentShort, recorduuid: String){// need to know relationship
        //create Message: NSManagedObject
        DispatchQueue.main.async(execute: { () -> Void in
            
            //let appDelegate = UIApplication.shared.delegate as? AppDelegate
            //let moc = (appDelegate?.persistentContainer.viewContext)!
            let moc = AppDelegate().CDStack.mainContext
            
            let commentMO = NSEntityDescription.insertNewObject(forEntityName: "Comment", into: moc) as! BreadCrumbs.Comment
            
            let predicate = NSPredicate(format: "recorduuid == %@", (self.viewbreadcrumb?.uRecordID!)!)
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Message")
            fetchRequest.predicate = predicate
            do {// change it, it not work y?
                let fetchedMsgs = try moc.fetch(fetchRequest) as! [Message]
                
                let ComMessage = fetchedMsgs[0]
                
                //let newCommets:[Comment] = [ComMessage, commentMO]
                //ComMessage.setValue(newCommets, forKey: "comments")
                
                //let addresses = newPerson.mutableSetValueForKey("addresses")
                //addresses.addObject(otherAddress)
                
                commentMO.setValue(comment.text, forKey: "text")
                commentMO.setValue(comment.username, forKey: "username")
                commentMO.setValue(comment.timeSent, forKey: "timeSent")
                //recorduuid
                commentMO.setValue(comment.userID, forKey: "userID")
                commentMO.setValue(recorduuid, forKey: "recorduuid")
                commentMO.message = ComMessage
                
                
                do {
                    try commentMO.managedObjectContext?.save()
                    //print("comment saved to coredata")
                } catch {
                    print(error)
                    print("cd error in create crumbs")
                    
                }
            } catch {
                print(error)
            }
        })
    }
    
    @IBAction func CancelComment(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submitComment(_ sender: AnyObject) {
        
        AddComment()
        print("comment added to cd and ck")
        dismiss(animated: true, completion: nil)
        
    }
}

protocol CreateCommentDelegate: class {
   func addNewComment(_ newComment: CommentShort)
}
