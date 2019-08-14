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
    @IBOutlet private weak var presentationStyleSegmentedControl: UISegmentedControl!
    @IBOutlet private weak var screenWidthSlider: UISlider!
    @IBOutlet private weak var shadowOpacitySlider: UISlider!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSideMenu()
        updateUI(settings: SideMenuSettings())
        updateMenus()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let sideMenuNavigationController = segue.destination as? SideMenuNavigationController else { return }
        sideMenuNavigationController.settings = makeSettings()
    }
    
    private func setupSideMenu() {
        // Define the menus
        SideMenuManager.default.leftMenuNavigationController = storyboard?.instantiateViewController(withIdentifier: "LeftMenuNavigationController") as? SideMenuNavigationController
        SideMenuManager.default.rightMenuNavigationController = storyboard?.instantiateViewController(withIdentifier: "RightMenuNavigationController") as? SideMenuNavigationController
        
        // Enable gestures. The left and/or right menus must be set up above for these to work.
        // Note that these continue to work on the Navigation Controller independent of the View Controller it displays!
        SideMenuManager.default.addPanGestureToPresent(toView: navigationController!.navigationBar)
        SideMenuManager.default.addScreenEdgePanGesturesToPresent(toView: view)
    }
    
    private func updateUI(settings: SideMenuSettings) {
        let styles:[UIBlurEffect.Style] = [.dark, .light, .extraLight]
        if let menuBlurEffectStyle = settings.blurEffectStyle {
            blurSegmentControl.selectedSegmentIndex = (styles.firstIndex(of: menuBlurEffectStyle) ?? 0) + 1
        } else {
            blurSegmentControl.selectedSegmentIndex = 0
        }

        blackOutStatusBar.isOn = settings.statusBarEndAlpha > 0
        menuAlphaSlider.value = Float(settings.presentationStyle.menuStartAlpha)
        menuScaleFactorSlider.value = Float(settings.presentationStyle.menuScaleFactor)
        presentingAlphaSlider.value = Float(settings.presentationStyle.presentingEndAlpha)
        presentingScaleFactorSlider.value = Float(settings.presentationStyle.presentingScaleFactor)
        screenWidthSlider.value = Float(settings.menuWidth / min(view.frame.width, view.frame.height))
        shadowOpacitySlider.value = Float(settings.presentationStyle.onTopShadowOpacity)
    }

    @IBAction private func changeControl(_ control: UIControl) {
        if control == presentationStyleSegmentedControl {
            var settings = makeSettings()
            settings.presentationStyle = selectedPresentationStyle()
            updateUI(settings: settings)
        }
        updateMenus()
    }

    private func updateMenus() {
        let settings = makeSettings()
        SideMenuManager.default.leftMenuNavigationController?.settings = settings
        SideMenuManager.default.rightMenuNavigationController?.settings = settings
    }

    private func selectedPresentationStyle() -> SideMenuPresentationStyle {
        let modes: [SideMenuPresentationStyle] = [.menuSlideIn, .viewSlideOut, .viewSlideOutMenuIn, .menuDissolveIn]
        return modes[presentationStyleSegmentedControl.selectedSegmentIndex]
    }

    private func makeSettings() -> SideMenuSettings {
        let presentationStyle = selectedPresentationStyle()
        presentationStyle.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "background"))
        presentationStyle.menuStartAlpha = CGFloat(menuAlphaSlider.value)
        presentationStyle.menuScaleFactor = CGFloat(menuScaleFactorSlider.value)
        presentationStyle.onTopShadowOpacity = shadowOpacitySlider.value
        presentationStyle.presentingEndAlpha = CGFloat(presentingAlphaSlider.value)
        presentationStyle.presentingScaleFactor = CGFloat(presentingScaleFactorSlider.value)

        var settings = SideMenuSettings()
        settings.presentationStyle = presentationStyle
        settings.menuWidth = min(view.frame.width, view.frame.height) * CGFloat(screenWidthSlider.value)
        let styles:[UIBlurEffect.Style?] = [nil, .dark, .light, .extraLight]
        settings.blurEffectStyle = styles[blurSegmentControl.selectedSegmentIndex]
        settings.statusBarEndAlpha = blackOutStatusBar.isOn ? 1 : 0

        return settings
    }
}

extension MainViewController: SideMenuNavigationControllerDelegate {
    
    func sideMenuWillAppear(menu: SideMenuNavigationController, animated: Bool) {
        print("SideMenu Appearing! (animated: \(animated))")
    }
    
    func sideMenuDidAppear(menu: SideMenuNavigationController, animated: Bool) {
        print("SideMenu Appeared! (animated: \(animated))")
    }
    
    func sideMenuWillDisappear(menu: SideMenuNavigationController, animated: Bool) {
        print("SideMenu Disappearing! (animated: \(animated))")
    }
    
    func sideMenuDidDisappear(menu: SideMenuNavigationController, animated: Bool) {
        print("SideMenu Disappeared! (animated: \(animated))")
    }
}
