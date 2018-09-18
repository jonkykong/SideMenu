//
//  UITableViewVibrantCell.swift
//  Pods
//
//  Created by Jon Kent on 1/14/16.
//
//

import UIKit

open class UITableViewVibrantCell: UITableViewCell {
    
    fileprivate var vibrancyView:UIVisualEffectView = UIVisualEffectView()
    fileprivate var vibrancySelectedBackgroundView:UIVisualEffectView = UIVisualEffectView()
    fileprivate var defaultSelectedBackgroundView:UIView?
    #if swift(>=4.2)
    open var blurEffectStyle: UIBlurEffect.Style? {
        didSet {
            updateBlur()
        }
    }
    #else
    open var blurEffectStyle: UIBlurEffectStyle? {
        didSet {
            updateBlur()
        }
    }
    #endif
    
    // For registering with UITableView without subclassing otherwise dequeuing instance of the cell causes an exception
    #if swift(>=4.2)
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    #else
    public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    #endif
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        vibrancyView.frame = bounds
        vibrancyView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        for view in subviews {
            vibrancyView.contentView.addSubview(view)
        }
        addSubview(vibrancyView)
        
        let blurSelectionEffect = UIBlurEffect(style: .light)
        vibrancySelectedBackgroundView.effect = blurSelectionEffect
        defaultSelectedBackgroundView = selectedBackgroundView
        
        updateBlur()
    }
    
    internal func updateBlur() {
        // shouldn't be needed but backgroundColor is set to white on iPad:
        backgroundColor = UIColor.clear
        
        #if swift(>=4.2)
        let uiTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
        #else
        let uiTransparencyEnabled = UIAccessibilityIsReduceTransparencyEnabled()
        #endif
        
        if let blurEffectStyle = blurEffectStyle, !uiTransparencyEnabled {
            let blurEffect = UIBlurEffect(style: blurEffectStyle)
            vibrancyView.effect = UIVibrancyEffect(blurEffect: blurEffect)
            
            if selectedBackgroundView != nil && selectedBackgroundView != vibrancySelectedBackgroundView {
                vibrancySelectedBackgroundView.contentView.addSubview(selectedBackgroundView!)
                selectedBackgroundView = vibrancySelectedBackgroundView
            }
        } else {
            vibrancyView.effect = nil
            selectedBackgroundView = defaultSelectedBackgroundView
        }
    }
}
