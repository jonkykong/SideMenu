//
//  MainViewController.swift
//
//  Created by Jon Kent on 11/12/15.
//  Copyright © 2015 Jon Kent. All rights reserved.
//

import SideMenu

class MainViewController: UIViewController {
    
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
        // Define the menus
        SideMenuManager.menuLeftNavigationController = storyboard!.instantiateViewController(withIdentifier: "LeftMenuNavigationController") as? UISideMenuNavigationController
        SideMenuManager.menuRightNavigationController = storyboard!.instantiateViewController(withIdentifier: "RightMenuNavigationController") as? UISideMenuNavigationController
        
        // Enable gestures. The left and/or right menus must be set up above for these to work.
        // Note that these continue to work on the Navigation Controller independent of the View Controller it displays!
        SideMenuManager.menuAddPanGestureToPresent(toView: self.navigationController!.navigationBar)
        SideMenuManager.menuAddScreenEdgePanGesturesToPresent(toView: self.navigationController!.view)
        
        // Set up a cool background image for demo purposes
        SideMenuManager.menuAnimationBackgroundColor = UIColor(patternImage: UIImage(named: "background")!)
    }
    
    private func setDefaults() {
        let modes:[SideMenuManager.MenuPresentMode] = [.menuSlideIn, .viewSlideOut, .menuDissolveIn]
        presentModeSegmentedControl.selectedSegmentIndex = modes.index(of: SideMenuManager.menuPresentMode)!
        
        let styles:[UIBlurEffectStyle] = [.dark, .light, .extraLight]
        if let menuBlurEffectStyle = SideMenuManager.menuBlurEffectStyle {
            blurSegmentControl.selectedSegmentIndex = styles.index(of: menuBlurEffectStyle) ?? 0
        } else {
            blurSegmentControl.selectedSegmentIndex = 0
        }
        
        darknessSlider.value = Float(SideMenuManager.menuAnimationFadeStrength)
        shadowOpacitySlider.value = Float(SideMenuManager.menuShadowOpacity)
        shrinkFactorSlider.value = Float(SideMenuManager.menuAnimationTransformScaleFactor)
        screenWidthSlider.value = Float(SideMenuManager.menuWidth / view.frame.width)
        blackOutStatusBar.isOn = SideMenuManager.menuFadeStatusBar
    }
    
    @IBAction private func changeSegment(segmentControl: UISegmentedControl) {
        switch segmentControl {
        case presentModeSegmentedControl:
            let modes:[SideMenuManager.MenuPresentMode] = [.menuSlideIn, .viewSlideOut, .viewSlideInOut, .menuDissolveIn]
            SideMenuManager.menuPresentMode = modes[segmentControl.selectedSegmentIndex]
        case blurSegmentControl:
            if segmentControl.selectedSegmentIndex == 0 {
                SideMenuManager.menuBlurEffectStyle = nil
            } else {
                let styles:[UIBlurEffectStyle] = [.dark, .light, .extraLight]
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
            SideMenuManager.menuAnimationTransformScaleFactor = CGFloat(slider.value)
        case screenWidthSlider:
            SideMenuManager.menuWidth = view.frame.width * CGFloat(slider.value)
        default: break;
        }
    }
    
    @IBAction private func changeSwitch(switchControl: UISwitch) {
        SideMenuManager.menuFadeStatusBar = switchControl.isOn
    }
}
