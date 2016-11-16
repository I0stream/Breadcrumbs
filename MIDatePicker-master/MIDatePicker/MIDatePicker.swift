//
//  MIDatePicker.swift
//  Agenda medica
//
//  Created by Mario on 15/06/16.
//  Copyright © 2016 Mario. All rights reserved. it's a me
//

import UIKit

protocol MIDatePickerDelegate: class {
    func miDatePicker(_ amDatePicker: MIDatePicker, didSelect time: Int)
    func miDatePickerDidCancelSelection(_ amDatePicker: MIDatePicker)
    //func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int
    //func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    //func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
}

class MIDatePicker: UIView, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: - Config
    struct Config {
        
        fileprivate let contentHeight: CGFloat = 250
        fileprivate let bouncingOffset: CGFloat = 20
        
        var times: [String] = ["4","8","12","24","48"]
        
        var confirmButtonTitle = "Confirm"
        var cancelButtonTitle = "Cancel"
        
        var headerHeight: CGFloat = 50
        
        var animationDuration: TimeInterval = 0.3
        
        var contentBackgroundColor: UIColor = UIColor.white
        var headerBackgroundColor: UIColor = UIColor(red: 248/255, green: 248/255, blue: 248/255, alpha: 1)
        //var confirmButtonColor: UIColor = UIColor.blueColor()
        //var cancelButtonColor: UIColor = UIColor.blackColor()
        
        var overlayBackgroundColor: UIColor = UIColor.black.withAlphaComponent(0.5)
        
        
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
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return config.times.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return config.times[row]
    }
    
    static func getFromNib() -> MIDatePicker {
        return UINib.init(nibName: String(describing: self), bundle: nil).instantiate(withOwner: self, options: nil).last as! MIDatePicker
    }

    // MARK: - IBAction
    @IBAction func confirmButtonDidTapped(_ sender: AnyObject) {
        //config.startDate = datePicker.date
        
        dismiss()
        delegate?.miDatePicker(self, didSelect: (picker?.selectedRow(inComponent: 0))!)
        //delegate?.miDatePicker(self, didSelect: datePicker.date)
        
    }
    @IBAction func cancelButtonDidTapped(_ sender: AnyObject) {
        dismiss()
        delegate?.miDatePickerDidCancelSelection(self)
    }
    
    // MARK: - Private
    fileprivate func setup(_ parentVC: UIViewController) {
        
        // Loading configuration
        
        //if let startDate = config.startDate {
        //    datePicker.date = startDate
        //}
        picker?.delegate = self
        picker?.dataSource = self
        picker?.showsSelectionIndicator = true
        
        headerViewHeightConstraint.constant = config.headerHeight
        
        confirmButton.setTitle(config.confirmButtonTitle, for: UIControlState())
        cancelButton.setTitle(config.cancelButtonTitle, for: UIControlState())
        
        //confirmButton.setTitleColor(config.confirmButtonColor, forState: .Normal)
        //cancelButton.setTitleColor(config.cancelButtonColor, forState: .Normal)
        
        headerView.backgroundColor = config.headerBackgroundColor
        backgroundView.backgroundColor = config.contentBackgroundColor
        
        // Overlay view constraints setup
        
        overlayButton = UIButton(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        overlayButton.backgroundColor = config.overlayBackgroundColor
        overlayButton.alpha = 0
        
        overlayButton.addTarget(self, action: #selector(cancelButtonDidTapped(_:)), for: .touchUpInside)
        
        if !overlayButton.isDescendant(of: parentVC.view) { parentVC.view.addSubview(overlayButton) }
        
        overlayButton.translatesAutoresizingMaskIntoConstraints = false
        
        parentVC.view.addConstraints([
            NSLayoutConstraint(item: overlayButton, attribute: .bottom, relatedBy: .equal, toItem: parentVC.view, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: overlayButton, attribute: .top, relatedBy: .equal, toItem: parentVC.view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: overlayButton, attribute: .leading, relatedBy: .equal, toItem: parentVC.view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: overlayButton, attribute: .trailing, relatedBy: .equal, toItem: parentVC.view, attribute: .trailing, multiplier: 1, constant: 0)
            ]
        )
        
        // Setup picker constraints
        
        frame = CGRect(x: 0, y: UIScreen.main.bounds.height, width: UIScreen.main.bounds.width, height: config.contentHeight + config.headerHeight)
        
        translatesAutoresizingMaskIntoConstraints = false
        
        bottomConstraint = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: parentVC.view, attribute: .bottom, multiplier: 1, constant: 0)
        
        if !isDescendant(of: parentVC.view) { parentVC.view.addSubview(self) }
        
        parentVC.view.addConstraints([
            bottomConstraint,
            NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: parentVC.view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: parentVC.view, attribute: .trailing, multiplier: 1, constant: 0)
            ]
        )
        addConstraint(
            NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: frame.height)
        )
        
        move(false)
        
    }
    
    
    fileprivate func move(_ goUp: Bool) {
        bottomConstraint.constant = goUp ? config.bouncingOffset : config.contentHeight + config.headerHeight
    }
    
    // MARK: - Public
    func show(inVC parentVC: UIViewController, completion: (() -> ())? = nil) {
        
        parentVC.view.endEditing(true)
        
        setup(parentVC)
        move(true)
        
        UIView.animate(
            withDuration: config.animationDuration, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 5, options: .curveEaseIn, animations: {
                
                parentVC.view.layoutIfNeeded()
                self.overlayButton.alpha = 1
                
            }, completion: { (finished) in
                completion?()
            }
        )
        
    }
    func dismiss(_ completion: (() -> ())? = nil) {
        
        move(false)
        
        UIView.animate(
            withDuration: config.animationDuration, animations: {
                
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
