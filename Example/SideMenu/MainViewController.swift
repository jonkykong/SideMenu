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
        SideMenuManager.menuLeftNavigationController = storyboard!.instantiateViewControllerWithIdentifier("LeftMenuNavigationController") as? UISideMenuNavigationController
        SideMenuManager.menuRightNavigationController = storyboard!.instantiateViewControllerWithIdentifier("RightMenuNavigationController") as? UISideMenuNavigationController
        
        // Enable gestures. The left and/or right menus must be set up above for these to work.
        // Note that these continue to work on the Navigation Controller independent of the View Controller it displays!
        SideMenuManager.menuAddPanGestureToPresent(toView: self.navigationController!.navigationBar)
        SideMenuManager.menuAddScreenEdgePanGesturesToPresent(toView: self.navigationController!.view)
        SideMenuManager.menuTransitionDelegate = self
        
        // Set up a cool background image for demo purposes
        SideMenuManager.menuAnimationBackgroundColor = UIColor(patternImage: UIImage(named: "background")!)
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
        shrinkFactorSlider.value = Float(SideMenuManager.menuAnimationTransformScaleFactor)
        screenWidthSlider.value = Float(SideMenuManager.menuWidth / view.frame.width)
        blackOutStatusBar.on = SideMenuManager.menuFadeStatusBar
    }
    
    @IBAction private func changeSegment(segmentControl: UISegmentedControl) {
        switch segmentControl {
        case presentModeSegmentedControl:
            let modes:[SideMenuManager.MenuPresentMode] = [.MenuSlideIn, .ViewSlideOut, .ViewSlideInOut, .MenuDissolveIn]
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
            SideMenuManager.menuAnimationTransformScaleFactor = CGFloat(slider.value)
        case screenWidthSlider:
            SideMenuManager.menuWidth = view.frame.width * CGFloat(slider.value)
        default: break;
        }
    }
    
    @IBAction private func changeSwitch(switchControl: UISwitch) {
        SideMenuManager.menuFadeStatusBar = switchControl.on
    }
}

extension MainViewController: menuTransitionDelegate {
    func menuWillShow(from direction: UIRectEdge) {
        print("MENU WILL SHOW")
    }
    
    func menuDidShow(from direction: UIRectEdge) {
        print("MENU DID SHOW")
    }
    
    func menuWillHide(from direction: UIRectEdge) {
        print("MENU WILL HIDE")
    }
    
    func menuDidHide(from direction: UIRectEdge) {
        print("MENU DID HIDE")
    }
}
