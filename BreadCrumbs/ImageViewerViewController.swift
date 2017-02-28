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
    
    var theImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ScrollZoomViewContrainer.delegate = self
        
        // Do any additional setup after loading the view.
        ImageImageView.contentMode = .scaleAspectFit
        ImageImageView.image = theImage
        
        ScrollZoomViewContrainer.minimumZoomScale=0.5;
        ScrollZoomViewContrainer.maximumZoomScale=6.0;
        ScrollZoomViewContrainer.contentSize = CGSize(width: 1280, height: 960)
        
    }

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
