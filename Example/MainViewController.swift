//
//  MainViewController.swift
//
//  Created by Jon Kent on 11/12/15.
//  Copyright © 2015 Jon Kent. All rights reserved.
//

import SideMenu

class MainViewController: UIViewController {

    @IBOutlet private weak var blackOutStatusBar: UISwitch!
    @IBOutlet private weak var blurSegmentControl: UISegmentedControl!
    @IBOutlet private weak var menuAlphaSlider: UISlider!
    @IBOutlet private weak var menuScaleFactorSlider: UISlider!
    @IBOutlet private weak var presentingAlphaSlider: UISlider!
    @IBOutlet private weak var presentingScaleFactorSlider: UISlider!
    @IBOutlet private weak var presentModeSegmentedControl: UISegmentedControl!
    @IBOutlet private weak var screenWidthSlider: UISlider!
    @IBOutlet private weak var shadowOpacitySlider: UISlider!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSideMenu()
        updateUI(settings: SideMenuSettings())
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let sideMenuNavigationController = segue.destination as? UISideMenuNavigationController else { return }
        sideMenuNavigationController.settings = makeSettings()
    }
    
    private func setupSideMenu() {
        // Define the menus
        SideMenuManager.default.menuLeftNavigationController = storyboard!.instantiateViewController(withIdentifier: "LeftMenuNavigationController") as? UISideMenuNavigationController
        SideMenuManager.default.menuRightNavigationController = storyboard!.instantiateViewController(withIdentifier: "RightMenuNavigationController") as? UISideMenuNavigationController
        
        // Enable gestures. The left and/or right menus must be set up above for these to work.
        // Note that these continue to work on the Navigation Controller independent of the View Controller it displays!
        SideMenuManager.default.addPanGestureToPresent(toView: navigationController!.navigationBar)
        SideMenuManager.default.addScreenEdgePanGesturesToPresent(toView: view)
    }
    
    private func updateUI(settings: SideMenuSettings) {
        let styles:[UIBlurEffect.Style] = [.dark, .light, .extraLight]
        if let menuBlurEffectStyle = settings.blurEffectStyle {
            blurSegmentControl.selectedSegmentIndex = styles.firstIndex(of: menuBlurEffectStyle) ?? 0
        } else {
            blurSegmentControl.selectedSegmentIndex = 0
        }

        blackOutStatusBar.isOn = settings.statusBarEndAlpha > 0
        menuAlphaSlider.value = Float(settings.presentStyle.menuStartAlpha)
        menuScaleFactorSlider.value = Float(settings.presentStyle.menuScaleFactor)
        presentingAlphaSlider.value = Float(settings.presentStyle.presentingEndAlpha)
        presentingScaleFactorSlider.value = Float(settings.presentStyle.presentingScaleFactor)
        screenWidthSlider.value = Float(settings.menuWidth / view.frame.width)
        shadowOpacitySlider.value = Float(settings.presentStyle.onTopShadowOpacity)
    }

    @IBAction private func changeControl(_ control: UIControl) {
        if control == presentModeSegmentedControl {
            var settings = makeSettings()
            settings.presentStyle = selectedPresentStyle()
            updateUI(settings: settings)
        }

        updateMenus()
    }

    private func updateMenus() {
        let settings = makeSettings()
        SideMenuManager.default.menuLeftNavigationController?.settings = settings
        SideMenuManager.default.menuRightNavigationController?.settings = settings
    }

    private func selectedPresentStyle() -> SideMenuPresentStyle {
        let modes: [SideMenuPresentStyle] = [.menuSlideIn, .viewSlideOut, .viewSlideOutMenuIn, .menuDissolveIn]
        return modes[presentModeSegmentedControl.selectedSegmentIndex]
    }

    private func makeSettings() -> SideMenuSettings {
        var settings = SideMenuSettings()

        var presentStyle = selectedPresentStyle()
        presentStyle.backgroundColor = UIColor(patternImage: UIImage(named: "background")!)
        presentStyle.menuStartAlpha = CGFloat(menuAlphaSlider.value)
        presentStyle.menuScaleFactor = CGFloat(menuScaleFactorSlider.value)
        presentStyle.onTopShadowOpacity = shadowOpacitySlider.value
        presentStyle.presentingEndAlpha = CGFloat(presentingAlphaSlider.value)
        presentStyle.presentingScaleFactor = CGFloat(presentingScaleFactorSlider.value)
        settings.presentStyle = presentStyle

        settings.menuWidth = view.frame.width * CGFloat(screenWidthSlider.value)
        let styles:[UIBlurEffect.Style?] = [nil, .dark, .light, .extraLight]
        settings.blurEffectStyle = styles[blurSegmentControl.selectedSegmentIndex]
        settings.statusBarEndAlpha = blackOutStatusBar.isOn ? 1 : 0

        return settings
    }
}

extension MainViewController: UISideMenuNavigationControllerDelegate {
    
    func sideMenuWillAppear(menu: UISideMenuNavigationController, animated: Bool) {
        print("SideMenu Appearing! (animated: \(animated))")
    }
    
    func sideMenuDidAppear(menu: UISideMenuNavigationController, animated: Bool) {
        print("SideMenu Appeared! (animated: \(animated))")
    }
    
    func sideMenuWillDisappear(menu: UISideMenuNavigationController, animated: Bool) {
        print("SideMenu Disappearing! (animated: \(animated))")
    }
    
    func sideMenuDidDisappear(menu: UISideMenuNavigationController, animated: Bool) {
        print("SideMenu Disappeared! (animated: \(animated))")
    }
}
