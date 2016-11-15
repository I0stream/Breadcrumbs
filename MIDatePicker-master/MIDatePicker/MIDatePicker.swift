//
//  MIDatePicker.swift
//  Agenda medica
//
//  Created by Mario on 15/06/16.
//  Copyright © 2016 Mario. All rights reserved. it's a me
//

import UIKit

protocol MIDatePickerDelegate: class {
    func miDatePicker(amDatePicker: MIDatePicker, didSelect time: Int)
    func miDatePickerDidCancelSelection(amDatePicker: MIDatePicker)
    //func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int
    //func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    //func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
}

class MIDatePicker: UIView, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: - Config
    struct Config {
        
        private let contentHeight: CGFloat = 250
        private let bouncingOffset: CGFloat = 20
        
        var times: [String] = ["4","8","12","24","48"]
        
        var confirmButtonTitle = "Confirm"
        var cancelButtonTitle = "Cancel"
        
        var headerHeight: CGFloat = 50
        
        var animationDuration: NSTimeInterval = 0.3
        
        var contentBackgroundColor: UIColor = UIColor.whiteColor()
        var headerBackgroundColor: UIColor = UIColor(red: 248/255, green: 248/255, blue: 248/255, alpha: 1)
        //var confirmButtonColor: UIColor = UIColor.blueColor()
        //var cancelButtonColor: UIColor = UIColor.blackColor()
        
        var overlayBackgroundColor: UIColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        
        
    }
    
    var config = Config()
    
    weak var delegate: MIDatePickerDelegate?
    
    // MARK: - IBOutlets
    @IBOutlet weak var picker: UIPickerView?
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
    
    var bottomConstraint: NSLayoutConstraint!
    var overlayButton: UIButton!
    
    // MARK: - Init
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return config.times.count
    }
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return config.times[row]
    }
    
    static func getFromNib() -> MIDatePicker {
        return UINib.init(nibName: String(self), bundle: nil).instantiateWithOwner(self, options: nil).last as! MIDatePicker
    }

    // MARK: - IBAction
    @IBAction func confirmButtonDidTapped(sender: AnyObject) {
        //config.startDate = datePicker.date
        
        dismiss()
        delegate?.miDatePicker(self, didSelect: (picker?.selectedRowInComponent(0))!)
        //delegate?.miDatePicker(self, didSelect: datePicker.date)
        
    }
    @IBAction func cancelButtonDidTapped(sender: AnyObject) {
        dismiss()
        delegate?.miDatePickerDidCancelSelection(self)
    }
    
    // MARK: - Private
    private func setup(parentVC: UIViewController) {
        
        // Loading configuration
        
        //if let startDate = config.startDate {
        //    datePicker.date = startDate
        //}
        picker?.delegate = self
        picker?.dataSource = self
        picker?.showsSelectionIndicator = true
        
        headerViewHeightConstraint.constant = config.headerHeight
        
        confirmButton.setTitle(config.confirmButtonTitle, forState: .Normal)
        cancelButton.setTitle(config.cancelButtonTitle, forState: .Normal)
        
        //confirmButton.setTitleColor(config.confirmButtonColor, forState: .Normal)
        //cancelButton.setTitleColor(config.cancelButtonColor, forState: .Normal)
        
        headerView.backgroundColor = config.headerBackgroundColor
        backgroundView.backgroundColor = config.contentBackgroundColor
        
        // Overlay view constraints setup
        
        overlayButton = UIButton(frame: CGRect(x: 0, y: 0, width: UIScreen.mainScreen().bounds.width, height: UIScreen.mainScreen().bounds.height))
        overlayButton.backgroundColor = config.overlayBackgroundColor
        overlayButton.alpha = 0
        
        overlayButton.addTarget(self, action: #selector(cancelButtonDidTapped(_:)), forControlEvents: .TouchUpInside)
        
        if !overlayButton.isDescendantOfView(parentVC.view) { parentVC.view.addSubview(overlayButton) }
        
        overlayButton.translatesAutoresizingMaskIntoConstraints = false
        
        parentVC.view.addConstraints([
            NSLayoutConstraint(item: overlayButton, attribute: .Bottom, relatedBy: .Equal, toItem: parentVC.view, attribute: .Bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: overlayButton, attribute: .Top, relatedBy: .Equal, toItem: parentVC.view, attribute: .Top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: overlayButton, attribute: .Leading, relatedBy: .Equal, toItem: parentVC.view, attribute: .Leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: overlayButton, attribute: .Trailing, relatedBy: .Equal, toItem: parentVC.view, attribute: .Trailing, multiplier: 1, constant: 0)
            ]
        )
        
        // Setup picker constraints
        
        frame = CGRect(x: 0, y: UIScreen.mainScreen().bounds.height, width: UIScreen.mainScreen().bounds.width, height: config.contentHeight + config.headerHeight)
        
        translatesAutoresizingMaskIntoConstraints = false
        
        bottomConstraint = NSLayoutConstraint(item: self, attribute: .Bottom, relatedBy: .Equal, toItem: parentVC.view, attribute: .Bottom, multiplier: 1, constant: 0)
        
        if !isDescendantOfView(parentVC.view) { parentVC.view.addSubview(self) }
        
        parentVC.view.addConstraints([
            bottomConstraint,
            NSLayoutConstraint(item: self, attribute: .Leading, relatedBy: .Equal, toItem: parentVC.view, attribute: .Leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .Trailing, relatedBy: .Equal, toItem: parentVC.view, attribute: .Trailing, multiplier: 1, constant: 0)
            ]
        )
        addConstraint(
            NSLayoutConstraint(item: self, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: frame.height)
        )
        
        move(false)
        
    }
    
    
    private func move(goUp: Bool) {
        bottomConstraint.constant = goUp ? config.bouncingOffset : config.contentHeight + config.headerHeight
    }
    
    // MARK: - Public
    func show(inVC parentVC: UIViewController, completion: (() -> ())? = nil) {
        
        parentVC.view.endEditing(true)
        
        setup(parentVC)
        move(true)
        
        UIView.animateWithDuration(
            config.animationDuration, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 5, options: .CurveEaseIn, animations: {
                
                parentVC.view.layoutIfNeeded()
                self.overlayButton.alpha = 1
                
            }, completion: { (finished) in
                completion?()
            }
        )
        
    }
    func dismiss(completion: (() -> ())? = nil) {
        
        move(false)
        
        UIView.animateWithDuration(
            config.animationDuration, animations: {
                
                self.layoutIfNeeded()
                self.overlayButton.alpha = 0
                
            }, completion: { (finished) in
                completion?()
                self.removeFromSuperview()
                self.overlayButton.removeFromSuperview()
            }
        )
        
    }
    
}
