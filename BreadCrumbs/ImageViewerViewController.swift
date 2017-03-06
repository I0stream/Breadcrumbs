//
//  ImageViewerViewController.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 2/24/17.
//  Copyright © 2017 Daniel Schliesing. All rights reserved.
//

import UIKit

class ImageViewerViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var ImageImageView: UIImageView!
    
    @IBOutlet weak var ScrollZoomViewContrainer: UIScrollView!
    
    @IBOutlet weak var SaveCancelMenuView: UIView!
    var theImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ScrollZoomViewContrainer.delegate = self
        
        ImageImageView.contentMode = .scaleAspectFit
        ImageImageView.image = theImage
        //heres the thought set the size of the container to suit the image
        //set the width or height to be the width or height - 100(top bar height) of the container/iphone
        
        
        
        //ImageImageView.center = ImageImageView.superview?.center
        
        ScrollZoomViewContrainer.minimumZoomScale=0.5;
        ScrollZoomViewContrainer.maximumZoomScale=6.0;
        ScrollZoomViewContrainer.contentSize = CGSize(width: 1280, height: 960)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressToSave(sender:)))
        longPressRecognizer.minimumPressDuration = 0.5
        ImageImageView.addGestureRecognizer(longPressRecognizer)
    }

    
    @IBAction func savefotoButtonAction(_ sender: Any) {
        saveimagePopUp()
        SaveCancelMenuView.isHidden = true

    }
    
    
    @IBAction func cancelSave(_ sender: Any) {
        SaveCancelMenuView.isHidden = true

    }
    
    //press to save functions
    func longPressToSave(sender: UILongPressGestureRecognizer) {
        //use popover revopop\\\poppy im poppy popover///\\\(((Rootless cosmopolitans)))
        SaveCancelMenuView.isHidden = false
    }
    
    func saveimagePopUp(){
        UIImageWriteToSavedPhotosAlbum(ImageImageView.image!, self, #selector(image(image:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    func image(image: UIImage!, didFinishSavingWithError error: NSError!, contextInfo: AnyObject!) {
        if (error != nil) {
            print(error)
            
        } else {
            print("alright")
        }
    }
    
    //zooming functions
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.ImageImageView
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func GoBackDismissButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

}
