//
//  MainVC.swift
//
//  Created by Jon Kent on 11/12/15.
//  Copyright © 2015 Jon Kent. All rights reserved.
//

import UIKit
import SideMenu

class MainVC: UIViewController {
    
    @IBOutlet private weak var presentModeSegmentedControl:UISegmentedControl!
    @IBOutlet private weak var blurSegmentControl:UISegmentedControl!
    @IBOutlet private weak var darknessSlider:UISlider!
    @IBOutlet private weak var shadowOpacitySlider:UISlider!
    @IBOutlet private weak var screenWidthSlider:UISlider!
    @IBOutlet private weak var shrinkFactorSlider:UISlider!
    @IBOutlet private weak var blackOutStatusBar:UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSideMenu()
        setDefaults()
    }
    
    private func setupSideMenu() {
        SideMenuManager.menuLeftNavigationController = storyboard!.instantiateViewControllerWithIdentifier("UILeftSideMenuNavigationController") as? UILeftSideMenuNavigationController
        SideMenuManager.menuRightNavigationController = storyboard!.instantiateViewControllerWithIdentifier("UIRightSideMenuNavigationController") as? UIRightSideMenuNavigationController
        SideMenuManager.menuAddPanGestureToPresent(toView: self.navigationController!.navigationBar)
        SideMenuManager.menuAddScreenEdgePanGesturesToPresent(toView: self.navigationController!.view)
        SideMenuManager.menuAnimationShrinkBackgroundColor = UIColor(patternImage: UIImage(named: "background")!)
    }
    
    private func setDefaults() {
        let modes:[SideMenuManager.MenuPresentMode] = [.MenuSlideIn, .ViewSlideOut, .MenuDissolveIn]
        presentModeSegmentedControl.selectedSegmentIndex = modes.indexOf(SideMenuManager.menuPresentMode)!
        
        let styles:[UIBlurEffectStyle] = [.Dark, .Light, .ExtraLight]
        if let menuBlurEffectStyle = SideMenuManager.menuBlurEffectStyle {
            blurSegmentControl.selectedSegmentIndex = styles.indexOf(menuBlurEffectStyle) ?? 0
        } else {
            blurSegmentControl.selectedSegmentIndex = 0
        }
        
        darknessSlider.value = Float(SideMenuManager.menuAnimationFadeStrength)
        shadowOpacitySlider.value = Float(SideMenuManager.menuShadowOpacity)
        shrinkFactorSlider.value = Float(SideMenuManager.menuAnimationShrinkStrength)
        screenWidthSlider.value = Float(SideMenuManager.menuWidth / view.frame.width)
        blackOutStatusBar.on = SideMenuManager.menuFadeStatusBar
    }
    
    @IBAction private func changeSegment(segmentControl: UISegmentedControl) {
        switch segmentControl {
        case presentModeSegmentedControl:
            let modes:[SideMenuManager.MenuPresentMode] = [.MenuSlideIn, .ViewSlideOut, .MenuDissolveIn]
            SideMenuManager.menuPresentMode = modes[segmentControl.selectedSegmentIndex]
        case blurSegmentControl:
            if segmentControl.selectedSegmentIndex == 0 {
                SideMenuManager.menuBlurEffectStyle = nil
            } else {
                let styles:[UIBlurEffectStyle] = [.Dark, .Light, .ExtraLight]
                SideMenuManager.menuBlurEffectStyle = styles[segmentControl.selectedSegmentIndex - 1]
            }
        default: break;
        }
    }
    
    @IBAction private func changeSlider(slider: UISlider) {
        switch slider {
        case darknessSlider:
            SideMenuManager.menuAnimationFadeStrength = CGFloat(slider.value)
        case shadowOpacitySlider:
            SideMenuManager.menuShadowOpacity = slider.value
        case shrinkFactorSlider:
            SideMenuManager.menuAnimationShrinkStrength = CGFloat(slider.value)
        case screenWidthSlider:
            SideMenuManager.menuWidth = view.frame.width * CGFloat(slider.value)
        default: break;
        }
    }
    
    @IBAction private func changeSwitch(switchControl: UISwitch) {
        SideMenuManager.menuFadeStatusBar = switchControl.on
    }
}