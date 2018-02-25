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
    
    @IBOutlet weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    
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
        
        self.ScrollZoomViewContrainer.minimumZoomScale = 1.0
        self.ScrollZoomViewContrainer.maximumZoomScale = 6.0
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressToSave(sender:)))
        longPressRecognizer.minimumPressDuration = 0.5
        ScrollZoomViewContrainer.addGestureRecognizer(longPressRecognizer)
    }
    
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if UIDevice.current.orientation.isLandscape {
            print("Landscape")
        } else {
            print("Portrait")
        }
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
            //failed to save
        } else {
            print("alright")
        }
    }
    
    func updateMinZoomScaleForSize(_ size: CGSize) {
        let widthScale = size.width / ImageImageView.bounds.width
        let heightScale = size.height / ImageImageView.bounds.height
        let minScale = min(widthScale, heightScale)
        
        ScrollZoomViewContrainer.minimumZoomScale = minScale
        ScrollZoomViewContrainer.zoomScale = minScale
    }
    
    //zooming functions
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.ImageImageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
        updateConstraintsForSize(view.bounds.size)
    }
    
    func updateConstraintsForSize(_ size: CGSize) {//when 'zooming out' it equalizes the side spaces
        
        /*let yOffset = max(0, ((size.height - ImageImageView.frame.height) / 2))
        
        imageViewTopConstraint.constant = yOffset
        imageViewBottomConstraint.constant = yOffset
        */
        //OMG if fucking worked
        var top = CGFloat(0)
        var left = CGFloat(0)
        if (self.ScrollZoomViewContrainer.contentSize.width < self.ScrollZoomViewContrainer.bounds.size.width) {
            left = (self.ScrollZoomViewContrainer.bounds.size.width - self.ScrollZoomViewContrainer.contentSize.width) * 0.5
        }
        if (self.ScrollZoomViewContrainer.contentSize.height < self.ScrollZoomViewContrainer.bounds.size.height) {
            top = (self.ScrollZoomViewContrainer.bounds.size.height - self.ScrollZoomViewContrainer.contentSize.height) * 0.5
        }
        self.ScrollZoomViewContrainer.contentInset = UIEdgeInsetsMake(top, left, top, left);
        
        
        /*let xOffset = max(0, ((size.width - ImageImageView.frame.width) / 2))
        if ImageImageView.frame.width > view.frame.width{
            imageViewLeadingConstraint.constant = xOffset
            imageViewTrailingConstraint.constant = xOffset
        }*/
        view.layoutIfNeeded()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func GoBackDismissButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    

}
