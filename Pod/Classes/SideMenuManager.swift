//
//  SideMenuManager.swift
//
//  Created by Jon Kent on 12/6/15.
//  Copyright © 2015 Jon Kent. All rights reserved.
//

import UIKit

@objcMembers
public final class SideMenuManager: NSObject {

    final private class SideMenuPanGestureRecognizer: UIPanGestureRecognizer {}
    final private class SideMenuScreenEdgeGestureRecognizer: UIScreenEdgePanGestureRecognizer {}

    public enum PresentDirection: Int { case
        left = 1,
        right = 0

        var edge: UIRectEdge {
            switch self {
            case .left: return .left
            case .right: return .right
            }
        }

        var name: String {
            switch self {
            case .left: return "menuLeftNavigationController"
            case .right: return "menuRightNavigationController"
            }
        }
    }

    private var _leftMenu: Protected<Menu?> =
        Protected(nil,
                  if: { $0?.isHidden != false },
                  else: { _ in Print.warning(.menuInUse, arguments: PresentDirection.left.name, required: true) } )

    private var _rightMenu: Protected<Menu?> =
        Protected(nil,
                  if: { $0?.isHidden != false },
                  else: { _ in Print.warning(.menuInUse, arguments: PresentDirection.right.name, required: true) } )

    private var switching: Bool = false

    /// Default instance of SideMenuManager.
    public static let `default` = SideMenuManager()

    /// Default instance of SideMenuManager (objective-C).
    public class var defaultManager: SideMenuManager {
        return SideMenuManager.default
    }

    /// The left menu.
    public var menuLeftNavigationController: UISideMenuNavigationController? {
        get { return _leftMenu.value }
        set(menu) { _leftMenu.value = menu }
    }
    
    /// The right menu.
    public var menuRightNavigationController: UISideMenuNavigationController? {
        get { return _rightMenu.value }
        set(menu) { _rightMenu.value = menu }
    }

    /**
     Adds screen edge gestures to a view to present a menu.
     
     - Parameter toView: The view to add gestures to.
     - Parameter forMenu: The menu (left or right) you want to add a gesture for. If unspecified, gestures will be added for both sides.
 
     - Returns: The array of screen edge gestures added to `toView`.
     */
    @discardableResult public func menuAddScreenEdgePanGesturesToPresent(toView view: UIView, forMenu sides: [PresentDirection] = [.left, .right]) -> [UIScreenEdgePanGestureRecognizer] {
        return sides.map { side in
            if menu(forSide: side) == nil {
                let methodName = #function // "menuAddScreenEdgePanGesturesToPresent"
                let suggestedMethodName = "menuAddScreenEdgePanGesturesToPresent(toView:forMenu:)"
                Print.warning(.screenGestureAdded, arguments: methodName, side.name, suggestedMethodName)
            }
            return self.addScreenEdgeGesture(to: view, edge: side.edge)
        }
    }
    
    /**
     Adds a pan edge gesture to a view to present menus.
     
     - Parameter toView: The view to add a pan gesture to.
     
     - Returns: The pan gesture added to `toView`.
     */
    @discardableResult public func menuAddPanGestureToPresent(toView view: UIView) -> UIPanGestureRecognizer {
        if menuLeftNavigationController ?? menuRightNavigationController == nil {
            Print.warning(.panGestureAdded, arguments: #function, PresentDirection.left.name, PresentDirection.right.name, required: true)
        }
        
        return addPresentPanGesture(to: view)
    }
}

internal extension SideMenuManager {

    func setMenu(_ menu: Menu?, forLeftSide leftSide: Bool) {
        switch leftSide {
        case true: menuLeftNavigationController = menu
        case false: menuRightNavigationController = menu
        }
    }
}

private extension SideMenuManager {

    @objc func handlePresentMenuScreenEdge(_ gesture: UIScreenEdgePanGestureRecognizer) {
        handleMenuPan(gesture)
    }

    @objc func handlePresentMenuPan(_ gesture: UIPanGestureRecognizer) {
        handleMenuPan(gesture)
    }

    func handleMenuPan(_ gesture: UIPanGestureRecognizer) {
        if let activeMenu = activeMenu {
            let width = activeMenu.menuWidth
            let distance = gesture.xTranslation / width
            switch (gesture.state) {
            case .began: break
            case .changed:
                if gesture.canSwitch {
                    switching = (distance > 0 && !activeMenu.leftSide) || (distance < 0 && activeMenu.leftSide)
                    if switching {
                        activeMenu.cancelMenuPan(gesture)
                        return
                    }
                }
            default:
                switching = false
            }

        } else {
            let leftSide: Bool
            if let gesture = gesture as? UIScreenEdgePanGestureRecognizer {
                leftSide = gesture.edges.contains(.left)
            } else {
                // not sure which way the user is swiping yet, so do nothing
                if gesture.xTranslation == 0 { return }

                leftSide = gesture.xTranslation > 0
            }

            guard let menu = menu(forLeftSide: leftSide) else { return }
            menu.presentFrom(activeViewController, interactively: true)
        }

        activeMenu?.handleMenuPan(gesture, true)
    }

    var activeMenu: Menu? {
        if menuLeftNavigationController?.isHidden == false { return menuLeftNavigationController }
        if menuRightNavigationController?.isHidden == false { return menuRightNavigationController }
        return nil
    }

    func menu(forSide: PresentDirection) -> Menu? {
        switch forSide {
        case .left: return menuLeftNavigationController
        case .right: return menuRightNavigationController
        }
    }

    func menu(forLeftSide leftSide: Bool) -> Menu? {
        return menu(forSide: leftSide ? .left : .right)
    }

    func addScreenEdgeGesture(to view: UIView, edge: UIRectEdge) -> UIScreenEdgePanGestureRecognizer {
        if let screenEdgeGestureRecognizer = view.gestureRecognizers?.first(where: { $0 is SideMenuScreenEdgeGestureRecognizer }) as? SideMenuScreenEdgeGestureRecognizer,
            screenEdgeGestureRecognizer.edges == edge {
            view.removeGestureRecognizer(screenEdgeGestureRecognizer)
        }
        return SideMenuScreenEdgeGestureRecognizer {
            $0.edges = edge
            $0.addTarget(self, action: #selector(handlePresentMenuScreenEdge(_:)))
            view.addGestureRecognizer($0)
        }
    }

    @discardableResult func addPresentPanGesture(to view: UIView) -> UIPanGestureRecognizer {
        if let panGestureRecognizer = view.gestureRecognizers?.first(where: { $0 is SideMenuPanGestureRecognizer }) as? SideMenuPanGestureRecognizer {
            return panGestureRecognizer
        }
        return SideMenuPanGestureRecognizer {
            $0.addTarget(self, action: #selector(handlePresentMenuPan(_:)))
            view.addGestureRecognizer($0)
        }
    }

    private var activeViewController: UIViewController? {
        return UIApplication.shared.keyWindow?.rootViewController?.activeViewController
    }
}

extension SideMenuManager: UISideMenuNavigationControllerTransitionDelegate {

    internal func sideMenuTransitionDidDismiss(menu: Menu) {
        defer { switching = false }
        guard switching, let switchToMenu = self.menu(forLeftSide: !menu.leftSide) else { return }
        switchToMenu.presentFrom(activeViewController, interactively: true)
    }
}

// Deprecations, to be removed at a future date.
extension SideMenuManager {
//    @available(*, deprecated, renamed: "menuPresentStyle")
//    open var menuPresentMode: MenuPresentStyle {
//        get { return menuPresentStyle }
//        set { menuPresentStyle = newValue }
//    }

    /**
     The push style of the menu.

     There are six modes in MenuPushStyle:
     - defaultBehavior: The view controller is pushed onto the stack.
     - popWhenPossible: If a view controller already in the stack is of the same class as the pushed view controller, the stack is instead popped back to the existing view controller. This behavior can help users from getting lost in a deep navigation stack.
     - preserve: If a view controller already in the stack is of the same class as the pushed view controller, the existing view controller is pushed to the end of the stack. This behavior is similar to a UITabBarController.
     - preserveAndHideBackButton: Same as .preserve and back buttons are automatically hidden.
     - replace: Any existing view controllers are released from the stack and replaced with the pushed view controller. Back buttons are automatically hidden. This behavior is ideal if view controllers require a lot of memory or their state doesn't need to be preserved..
     - subMenu: Unlike all other behaviors that push using the menu's presentingViewController, this behavior pushes view controllers within the menu.  Use this behavior if you want to display a sub menu.
     */
    //    open var menuPushStyle: MenuPushStyle = .defaultBehavior

    /**
     The presentation stayle of the menu.

     There are four modes in MenuPresentStyle:
     - menuSlideIn: Menu slides in over of the existing view.
     - viewSlideOut: The existing view slides out to reveal the menu.
     - viewSlideInOut: The existing view slides out while the menu slides in.
     - menuDissolveIn: The menu dissolves in over the existing view controller.
     */
    //    open var menuPresentStyle: MenuPresentStyle = .viewSlideOut

    /// Prevents the same view controller (or a view controller of the same class) from being pushed more than once. Defaults to true.
    //    open var menuAllowPushOfSameClassTwice = true

    /**
     Width of the menu when presented on screen, showing the existing view controller in the remaining space. Default is 75% of the screen width or 240 points, whichever is smaller.

     Note that each menu's width can be overridden using the `menuWidth` property on any `UISideMenuNavigationController` instance.
     */
    //    open var menuWidth: CGFloat = {
    //        let appScreenRect = UIApplication.shared.keyWindow?.bounds ?? UIWindow().bounds
    //        let minimumSize = min(appScreenRect.width, appScreenRect.height)
    //        return min(round(minimumSize * 0.75), 240)
    //    }()

    /// Duration of the animation when the menu is presented without gestures. Default is 0.35 seconds.
    //    open var menuAnimationPresentDuration: Double = 0.35

    /// Duration of the animation when the menu is dismissed without gestures. Default is 0.35 seconds.
    //    open var menuAnimationDismissDuration: Double = 0.35

    /// Duration of the remaining animation when the menu is partially dismissed with gestures. Default is 0.35 seconds.
    //    open var menuAnimationCompleteGestureDuration: Double = 0.35

    /// Amount to fade the existing view controller when the menu is presented. Default is 0 for no fade. Set to 1 to fade completely.
    //    open var menuAnimationFadeStrength: CGFloat = 0

    /// The amount to scale the existing view controller or the menu view controller depending on the `menuPresentMode`. Default is 1 for no scaling. Less than 1 will shrink, greater than 1 will grow.
    //    open var menuAnimationTransformScaleFactor: CGFloat = 1

    /// The background color behind menu animations. Depending on the animation settings this may not be visible. If `menuFadeStatusBar` is true, this color is used to fade it. Default is black.
    //    open var menuAnimationBackgroundColor: UIColor?

    /// The shadow opacity around the menu view controller or existing view controller depending on the `menuPresentMode`. Default is 0.5 for 50% opacity.
    //    open var menuShadowOpacity: Float = 0.5

    /// The shadow color around the menu view controller or existing view controller depending on the `menuPresentMode`. Default is black.
    //    open var menuShadowColor = UIColor.black

    /// The radius of the shadow around the menu view controller or existing view controller depending on the `menuPresentMode`. Default is 5.
    //    open var menuShadowRadius: CGFloat = 5

    /// Enable or disable interaction with the presenting view controller while the menu is displayed. Enabling may make it difficult to dismiss the menu or cause exceptions if the user tries to present and already presented menu. Default is false.
    //    open var menuPresentingViewControllerUserInteractionEnabled: Bool = false

    /// The strength of the parallax effect on the existing view controller. Does not apply to `menuPresentMode` when set to `ViewSlideOut`. Default is 0.
    //    open var menuParallaxStrength: Int = 0

    /// Draws the `menuAnimationBackgroundColor` behind the status bar. Default is true.
    //    open var menuFadeStatusBar = true

    /// The animation options when a menu is displayed. Ignored when displayed with a gesture.
    //    open var menuAnimationOptions: UIView.AnimationOptions = .curveEaseInOut

    ///    Animation curve of the remaining animation when the menu is partially dismissed with gestures. Default is .easeIn.
    //    open var menuAnimationCompletionCurve: UIView.AnimationCurve = .easeIn

    /// The animation spring damping when a menu is displayed. Ignored when displayed with a gesture.
    //    open var menuAnimationUsingSpringWithDamping: CGFloat = 1

    /// The animation initial spring velocity when a menu is displayed. Ignored when displayed with a gesture.
    //    open var menuAnimationInitialSpringVelocity: CGFloat = 1

    /**
     Automatically dismisses the menu when another view is pushed from it.

     Note: to prevent the menu from dismissing when presenting, set modalPresentationStyle = .overFullScreen
     of the view controller being presented in storyboard or during its initalization.
     */
    //    open var menuDismissOnPush = true

    /// Forces menus to always animate when appearing or disappearing, regardless of a pushed view controller's animation.
    //    open var menuAlwaysAnimate = false

    /// Automatically dismisses the menu when app goes to the background.
    //    open var menuDismissWhenBackgrounded = true

    /**
     The blur effect style of the menu if the menu's root view controller is a UITableViewController or UICollectionViewController.

     - Note: If you want cells in a UITableViewController menu to show vibrancy, make them a subclass of UITableViewVibrantCell.
     */
//    open var menuBlurEffectStyle: UIBlurEffect.Style? {
//        didSet {
//            if oldValue != menuBlurEffectStyle {
//                updateBlurIfNecessary()
//            }
//        }
//    }
//
//    /// The left menu.
//    open var menuLeftNavigationController: UISideMenuNavigationController? {
//        didSet {
//            if !setMenu(from: oldValue, to: menuLeftNavigationController, side: .left) {
//                menuLeftNavigationController = oldValue
//            }
//        }
//    }
//
//    /// The right menu.
//    open var menuRightNavigationController: UISideMenuNavigationController? {
//        didSet {
//            if !setMenu(from: oldValue, to: menuRightNavigationController, side: .right) {
//                menuRightNavigationController = oldValue
//            }
//        }
//    }
//
//    /// The left menu swipe to dismiss gesture.
//    open private(set) weak var menuLeftSwipeToDismissGesture: UIPanGestureRecognizer? {
//        didSet {
//            oldValue?.view?.removeGestureRecognizer(oldValue!)
//        }
//    }
//
//    open private(set) weak var menuRightSwipeToDismissGesture: UIPanGestureRecognizer? {
//        didSet {
//            oldValue?.view?.removeGestureRecognizer(oldValue!)
//        }
//    }
//
//    open var menuEnableSwipeGestures: Bool = true {
//        didSet {
//            setupSwipeGestures()
//        }
//    }
//    /**
//     Adds screen edge gestures to a view to present a menu.
//
//     - Parameter toView: The view to add gestures to.
//     - Parameter forMenu: The menu (left or right) you want to add a gesture for. If unspecified, gestures will be added for both sides.
//
//     - Returns: The array of screen edge gestures added to `toView`.
//     */
//    @discardableResult open func menuAddScreenEdgePanGesturesToPresent(toView view: UIView, forMenu sides: [PresentDirection] = [.left, .right]) -> [UIScreenEdgePanGestureRecognizer] {
//        sides.forEach { side in
//            if menu(forSide: side) == nil {
//                let methodName = #function // "menuAddScreenEdgePanGesturesToPresent"
//                let suggestedMethodName = "menuAddScreenEdgePanGesturesToPresent(toView:forMenu:)"
//                Print.warning(.screenGestureAdded, arguments: methodName, side.name, suggestedMethodName)
//            }
//        }
//
//        let edges: [UIRectEdge] = sides.map { $0.edge }
//        return addPresentScreenEdgePanGestures(to: view, for: edges)
//    }
//
//    /**
//     Adds a pan edge gesture to a view to present menus.
//
//     - Parameter toView: The view to add a pan gesture to.
//
//     - Returns: The pan gesture added to `toView`.
//     */
//    @discardableResult open func menuAddPanGestureToPresent(toView view: UIView) -> UIPanGestureRecognizer {
//        if menuLeftNavigationController ?? menuRightNavigationController == nil {
//            Print.warning(.panGestureAdded, arguments: #function, PresentDirection.left.name, PresentDirection.right.name, required: true)
//        }
//
//        return addPresentPanGesture(to: view)
//    }
}
