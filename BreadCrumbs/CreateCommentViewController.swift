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
    
    let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext //yay

    
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func CancelComment(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }

    
    @IBAction func MakeComment(_ sender: AnyObject) {
    }
    
    //test msglength
    func msgLengthTest() -> Bool {
        if WriteCommentTextView.text.characters.count >= 126 || WriteCommentTextView.text.characters.count < 1 || WriteCommentTextView.text == "What do you think?" {//fixed 256 off by one error; if want to shorten to 128 make sure to set as 129
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
        if WriteCommentTextView.text != "What do you think?" && WriteCommentTextView.text.characters.count <= 126 {
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
            let msgCharCount = WriteCommentTextView.text.characters.count
            charCount.text = String(126 - msgCharCount)
        }else {
            charCount.text = String(126)
        }
        if WriteCommentTextView.text.characters.count >= 126 {
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
    
    func AddComment(){
        let date = Date()
        let newComment = CommentShort(username: NSUserData.string(forKey: "userName")!, text: WriteCommentTextView.text, timeSent: date)
        
        AddToCD(newComment)
        AddToCK(newComment)
    }
    func AddToCK(_ comment: CommentShort){//need to know reference of crumb
        //upload to iCloud
        
        let container = CKContainer.default()
        let publicData = container.publicCloudDatabase
        
        let record = CKRecord(recordType: "Comment")
        
        record.setValue(comment.timeSent, forKey: "timeSent")
        record.setValue(comment.username, forKey: "userName")
        record.setValue(comment.text, forKey: "text")
        
        let recordid = CKRecordID(recordName: (viewbreadcrumb?.uRecordID)!)
        
        let ref = CKReference(recordID: recordid, action: .deleteSelf)
        record.setValue(ref, forKey: "ownerReference")
        publicData.save(record, completionHandler: { record, error in
            if error != nil {
                print(error.debugDescription)
                print("ck error in create comment")
            }
        })
    }
    func AddToCD(_ comment: CommentShort){// need to know relationship
        //create Message: NSManagedObject
        
        let commentMO = NSEntityDescription.insertNewObject(forEntityName: "Comment", into: self.managedObjectContext) as! BreadCrumbs.Comment
        
        let predicate = NSPredicate(format: "recorduuid == %@", (viewbreadcrumb?.uRecordID!)!)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Message")
        fetchRequest.predicate = predicate
        do {// change it, it not work y?
            let fetchedMsgs = try managedObjectContext.fetch(fetchRequest) as! [Message]
            
            let ComMessage = fetchedMsgs[0]
            commentMO.message = ComMessage
            
            commentMO.setValue(comment.text, forKey: "text")
            commentMO.setValue(comment.username, forKey: "username")
            commentMO.setValue(comment.timeSent, forKey: "timeSent")

            do {
                try commentMO.managedObjectContext?.save()
                //print("saved to coredata")
            } catch {
                print(error)
                print("cd error in write crumbs")
                
            }
        } catch {
            print(error)
        }

    }
    
    @IBAction func submitComment(_ sender: AnyObject) {
        AddComment()
    }
}

protocol CreateCommentDelegate: class {
   func addNewComment(_ newComment: CommentShort)
}
