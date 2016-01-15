//
//  UITableViewVibrantCell.swift
//  Pods
//
//  Created by Jon Kent on 1/14/16.
//
//

import UIKit

public class UITableViewVibrantCell: UITableViewCell {
    
    private var vibrancyView:UIVisualEffectView = UIVisualEffectView()
    private var vibrancySelectedBackgroundView:UIVisualEffectView = UIVisualEffectView()
    private var defaultSelectedBackgroundView:UIView?
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        vibrancyView.frame = bounds
        vibrancyView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        for view in subviews {
            vibrancyView.contentView.addSubview(view)
        }
        addSubview(vibrancyView)
        
        let blurSelectionEffect = UIBlurEffect(style: .Light)
        vibrancySelectedBackgroundView.effect = blurSelectionEffect
        defaultSelectedBackgroundView = selectedBackgroundView
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        // shouldn't be needed but backgroundColor is set to white on iPad:
        backgroundColor = UIColor.clearColor()
        
        if !UIAccessibilityIsReduceTransparencyEnabled() && SideMenuManager.menuBlurEffectStyle != nil {
            let blurEffect = UIBlurEffect(style: SideMenuManager.menuBlurEffectStyle!)
            vibrancyView.effect = UIVibrancyEffect(forBlurEffect: blurEffect)
            
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
