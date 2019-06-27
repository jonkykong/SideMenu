//
//  UISideMenuNavigationController.swift
//
//  Created by Jon Kent on 1/14/16.
//  Copyright © 2016 Jon Kent. All rights reserved.
//

import UIKit

@objc public enum MenuPushStyle: Int {
    case defaultBehavior,
    popWhenPossible,
    replace,
    preserve,
    preserveAndHideBackButton,
    subMenu
}

internal protocol MenuModel: TransitionModel {
    var allowPushOfSameClassTwice: Bool { get }
    var alwaysAnimate: Bool { get }
    var animationOptions: UIView.AnimationOptions { get }
    var blurEffectStyle: UIBlurEffect.Style? { get }
    var completeGestureDuration: Double { get }
    var completionCurve: UIView.AnimationCurve { get }
    var dismissDuration: Double { get }
    var dismissOnPresent: Bool { get }
    var dismissOnPush: Bool { get }
    var dismissWhenBackgrounded: Bool { get }
    var enableSwipeGestures: Bool { get }
    var fadeStatusBarStrength: CGFloat { get }
    var initialSpringVelocity: CGFloat { get }
    var presentingViewControllerUserInteractionEnabled: Bool { get }
    var presentingViewControllerUseSnapshot: Bool { get }
    var presentDuration: Double { get }
    var presentStyle: MenuPresentStyle { get }
    var pushStyle: MenuPushStyle { get }
    var usingSpringWithDamping: CGFloat { get }
    var menuWidth: CGFloat { get }
}

@objc public protocol UISideMenuNavigationControllerDelegate {
    @objc optional func sideMenuWillAppear(menu: UISideMenuNavigationController, animated: Bool)
    @objc optional func sideMenuDidAppear(menu: UISideMenuNavigationController, animated: Bool)
    @objc optional func sideMenuWillDisappear(menu: UISideMenuNavigationController, animated: Bool)
    @objc optional func sideMenuDidDisappear(menu: UISideMenuNavigationController, animated: Bool)
}

internal protocol UISideMenuNavigationControllerTransitionDelegate: class {
    func sideMenuTransitionDidDismiss(menu: Menu)
}

internal typealias Menu = UISideMenuNavigationController

@objcMembers
open class UISideMenuNavigationController: UINavigationController, MenuModel {

    private enum PropertyName: String { case
        leftSide
    }

    private lazy var _leftSide = Protected(false,
                                           if: { [weak self] _ in self?.isHidden != false },
                                           else: { _ in Menu.elseCondition(.leftSide) } )
    private weak var _sideMenuManager: SideMenuManager?
    private weak var foundDelegate: UISideMenuNavigationControllerDelegate?
    private weak var interactionController: SideMenuInteractionController?
    private var interactive: Bool = false
    private var originalBackgroundColor: UIColor?
    private var rotating: Bool = false
    private var transitionController: SideMenuTransitionController?

    /// Delegate for receiving appear and disappear related events. If `nil` the visible view controller that displays a `UISideMenuNavigationController` automatically receives these events.
    open weak var sideMenuDelegate: UISideMenuNavigationControllerDelegate?

    /// The swipe to dismiss gesture.
    open private(set) weak var swipeToDismissGesture: UIPanGestureRecognizer? = nil

    open var sideMenuManager: SideMenuManager {
        get { return _sideMenuManager ?? SideMenuManager.default }
        set {
            newValue.setMenu(self, forLeftSide: leftSide)
            _sideMenuManager = newValue
        }
    }

    #if !STFU_SIDEMENU
    // This override prevents newbie developers from creating black/blank menus and opening newbie issues.
    // If you would like to remove this override, define STFU_SIDEMENU in the Active Compilation Conditions of your .plist file.
    // Sorry for the inconvenience experienced developers :(
    @available(*, unavailable, renamed: "init(rootViewController:)")
    public init() {
        fatalError("init is not available")
    }
    
//    public override init(rootViewController: UIViewController) {
//        super.init(rootViewController: rootViewController)
//    }
//
//    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
//        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
//    }
    #endif

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    deinit {
        print("Menu deinit")
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        sideMenuManager.setMenu(self, forLeftSide: leftSide)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if topViewController == nil {
            Print.warning(.emptyMenu)
        }

        // Dismiss keyboard to prevent weird keyboard animations from occurring during transition
        presentingViewController?.view.endEditing(true)

        foundDelegate = nil
        activeDelegate?.sideMenuWillAppear?(menu: self, animated: animated)
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // We had presented a view before, so lets dismiss ourselves as already acted upon
        if view.isHidden {
            transitionController?.transition(presenting: false, animated: false)
            dismiss(animated: false, completion: { [weak self] in
                self?.view.isHidden = false
            })
        } else {
            activeDelegate?.sideMenuDidAppear?(menu: self, animated: animated)
        }
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // When presenting a view controller from the menu, the menu view gets moved into another transition view above our transition container
        // which can break the visual layout we had before. So, we move the menu view back to its original transition view to preserve it.
        if dismissOnPresent && !isBeingDismissed {
            // We're presenting a view controller from the menu, so we need to hide the menu so it isn't showing when the presented view is dismissed.
            if let presentingView = presentingViewController?.view, let containerView = presentingView.superview {
                containerView.addSubview(view)
            }

            transitionController?.transition(presenting: false, animated: animated, alongsideTransition: { [weak self] in
                guard let self = self else { return }
                self.activeDelegate?.sideMenuWillDisappear?(menu: self, animated: animated)
            }, complete: false, completion: { [weak self] _ in
                guard let self = self else { return }
                self.activeDelegate?.sideMenuDidDisappear?(menu: self, animated: animated)
                self.view.isHidden = true
            })
        } else {
            activeDelegate?.sideMenuWillDisappear?(menu: self, animated: animated)
        }
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // Work-around: if the menu is dismissed without animation the transition logic is never called to restore the
        // the view hierarchy leaving the screen black/empty. This is because the transition moves views within a container
        // view, but dismissing without animation removes the container view before the original hierarchy is restored.
        // This check corrects that.
        if let activeDelegate = activeDelegate as? UIViewController, activeDelegate.view.window == nil {
            transitionController?.transition(presenting: false, animated: false)
        }

        // Clear selecton on UITableViewControllers when reappearing using custom transitions
        if let tableViewController = topViewController as? UITableViewController,
            let tableView = tableViewController.tableView,
            let indexPaths = tableView.indexPathsForSelectedRows,
            tableViewController.clearsSelectionOnViewWillAppear {
            indexPaths.forEach { tableView.deselectRow(at: $0, animated: false) }
        }

        activeDelegate?.sideMenuDidDisappear?(menu: self, animated: animated)

        if dismissOnPresent && !isBeingDismissed {
            view.isHidden = true
        } else {
            transitionController = nil
        }
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Don't bother resizing if the view isn't visible
        guard let transitionController = transitionController, !view.isHidden else { return }

        coordinator.animate(alongsideTransition: { _ in
            transitionController.layout()
        }, completion: nil)
    }
    
    override open func pushViewController(_ viewController: UIViewController, animated: Bool) {
        let push = shouldPushViewController(viewController: viewController, animated: animated) { [weak self] _ in
            self?.foundDelegate = nil
        }
        
        if push {
            super.pushViewController(viewController, animated: animated)
        }
    }

    /// Indicates if the menu is anywhere in the view hierarchy, even if covered by another view controller.
    open override var isHidden: Bool {
        return presentingViewController == nil
    }

    open override var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        get { return self }
        set { print(self) } // TODO: Warning
    }

    // MARK: Interface

    /// Prevents the same view controller (or a view controller of the same class) from being pushed more than once. Defaults to true.
    @IBInspectable var allowPushOfSameClassTwice: Bool = true

    /// Forces menus to always animate when appearing or disappearing, regardless of a pushed view controller's animation.
    @IBInspectable var alwaysAnimate: Bool = true

    /// The animation options when a menu is displayed. Ignored when displayed with a gesture.
    @IBInspectable open var animationOptions: UIView.AnimationOptions = .curveEaseInOut

    /**
     The blur effect style of the menu if the menu's root view controller is a UITableViewController or UICollectionViewController.

     - Note: If you want cells in a UITableViewController menu to show vibrancy, make them a subclass of UITableViewVibrantCell.
     */
    open var blurEffectStyle: UIBlurEffect.Style? = nil {
        didSet {
            setupBlur()
        }
    }

    /// Duration of the remaining animation when the menu is partially dismissed with gestures. Default is 0.35 seconds.
    @IBInspectable open var completeGestureDuration: Double = 0.35

    /// Animation curve of the remaining animation when the menu is partially dismissed with gestures. Default is .easeIn.
    @IBInspectable open var completionCurve: UIView.AnimationCurve = .easeIn

    /// Duration of the animation when the menu is dismissed without gestures. Default is 0.35 seconds.
    @IBInspectable open var dismissDuration: Double = 0.35

    /// Automatically dismisses the menu when another view is presented from it.
    @IBInspectable open var dismissOnPresent: Bool = true

    /// Automatically dismisses the menu when another view controller is pushed from it.
    @IBInspectable open var dismissOnPush: Bool = true

    /// Automatically dismisses the menu when app goes to the background.
    @IBInspectable open var dismissWhenBackgrounded: Bool = true

    /// Enable or disable gestures that would swipe to dismiss the menu. Default is true.
    @IBInspectable open var enableSwipeGestures: Bool = true {
        didSet {
            setupSwipeGestures()
        }
    }

    /// Draws `presentStyle.backgroundColor` behind the status bar. Default is 1.
    @IBInspectable open var fadeStatusBarStrength: CGFloat = 1

    /// The animation initial spring velocity when a menu is displayed. Ignored when displayed with a gesture.
    @IBInspectable open var initialSpringVelocity: CGFloat = 1

    /// Whether the menu appears on the right or left side of the screen. Right is the default. This property cannot be changed after the menu has loaded.
    @IBInspectable open var leftSide: Bool {
        get { return _leftSide.value }
        set { _leftSide.value = newValue }
    }

    /// Width of the menu when presented on screen, showing the existing view controller in the remaining space. Default is zero.
    @IBInspectable open var menuWidth: CGFloat = {
        let appScreenRect = UIApplication.shared.keyWindow?.bounds ?? UIWindow().bounds
        let minimumSize = min(appScreenRect.width, appScreenRect.height)
        return min(round(minimumSize * 0.75), 240)
    }()

    /// Enable or disable interaction with the presenting view controller while the menu is displayed. Enabling may make it difficult to dismiss the menu or cause exceptions if the user tries to present and already presented menu. `presentingViewControllerUseSnapshot` must also set to false. Default is false.
    @IBInspectable open var presentingViewControllerUserInteractionEnabled: Bool = false

    /// Use a snapshot for the presenting vierw controller while the menu is displayed. Useful when layout changes occur during transitions. Not recommended for apps that support rotation. Default is false.
    @IBInspectable open var presentingViewControllerUseSnapshot: Bool = false

    /// Duration of the animation when the menu is presented without gestures. Default is 0.35 seconds.
    @IBInspectable var presentDuration: Double = 0.35

    /**
     The presentation stayle of the menu.

     There are four modes in MenuPresentStyle:
     - menuSlideIn: Menu slides in over of the existing view.
     - viewSlideOut: The existing view slides out to reveal the menu.
     - viewSlideInOut: The existing view slides out while the menu slides in.
     - menuDissolveIn: The menu dissolves in over the existing view controller.
     */
    @IBInspectable open var presentStyle: MenuPresentStyle = .viewSlideOut

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
    @IBInspectable open var pushStyle: MenuPushStyle = .defaultBehavior

    /// The animation spring damping when a menu is displayed. Ignored when displayed with a gesture.
    @IBInspectable var usingSpringWithDamping: CGFloat = 1
}

// IMPORTANT: These methods must be declared open or they will not be called.
extension UISideMenuNavigationController: UIViewControllerTransitioningDelegate {

    open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionController = SideMenuTransitionController(
            config: self,
            delegate: self)
        return transitionController
    }

    open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionController
    }

    open func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionController(using: animator)
    }

    open func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionController(using: animator)
    }

    open func interactionController(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard interactive else { return nil }
        let interactionController = SideMenuInteractionController(cancelWhenBackgrounded: dismissWhenBackgrounded, completionCurve: completionCurve)
        self.interactionController = interactionController
        return interactionController
    }
}

extension UISideMenuNavigationController: SideMenuTransitionControllerDelegate {

    internal func sideMenuTransitionController(_ transitionController: SideMenuTransitionController, didDismiss viewController: UIViewController) {
        sideMenuManager.sideMenuTransitionDidDismiss(menu: self)
    }

    internal func sideMenuTransitionController(_ transitionController: SideMenuTransitionController, didPresent viewController: UIViewController) {
        guard !presentingViewControllerUserInteractionEnabled else { return }

        let panGesture = UIPanGestureRecognizer()
        panGesture.cancelsTouchesInView = false
        panGesture.addTarget(self, action: #selector(handleDismissMenuPan(_:)))
        view.superview?.addGestureRecognizer(panGesture)

        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.addTarget(self, action: #selector(handleDismissMenuTap(_:)))
        tapGestureRecognizer.cancelsTouchesInView = false
        view.superview?.addGestureRecognizer(tapGestureRecognizer)
    }
}

internal extension UISideMenuNavigationController {

    func handleMenuPan(_ gesture: UIPanGestureRecognizer, _ presenting: Bool) {
        let width = menuWidth
        let distance = gesture.xTranslation / width
        let progress = max(min(distance * factor(presenting), 1), 0)
        switch (gesture.state) {
        case .began:
            if !presenting {
                dismissMenu(animated: true, interactively: true)
            }
            interactionController?.handle(state: .update(progress: progress))
        case .changed:
            interactionController?.handle(state: .update(progress: progress))
        case .ended:
            let velocity = gesture.xVelocity * factor(presenting)
            let finished = velocity >= 100 || velocity >= -50 && abs(progress) >= 0.5
            interactionController?.handle(state: finished ? .finish : .cancel)
        default:
            interactionController?.handle(state: .cancel)
        }
    }

    func cancelMenuPan(_ gesture: UIPanGestureRecognizer) {
        interactionController?.handle(state: .cancel)
    }

    func dismissMenu(animated flag: Bool, interactively interactive: Bool, completion: (() -> Void)? = nil) {
        self.interactive = interactive
        dismiss(animated: flag, completion: completion)
    }

    // Note: although this method is syntactically reversed it allows the interactive property to scoped privately
    func presentFrom(_ viewControllerToPresentFrom: UIViewController?, interactively interactive: Bool, completion: (() -> Void)? = nil) {
        guard let viewControllerToPresentFrom = viewControllerToPresentFrom else { return }
        self.interactive = interactive
        viewControllerToPresentFrom.present(self, animated: true, completion: completion)
    }
}

private extension UISideMenuNavigationController {

    func shouldPushViewController(viewController: UIViewController, animated: Bool, completion: ((Bool) -> Void)?) -> Bool {
        guard viewControllers.count > 0 && pushStyle != .subMenu else {
            // NOTE: pushViewController is called by init(rootViewController: UIViewController)
            // so we must perform the normal super method in this case
            return true
        }

        let splitViewController = presentingViewController as? UISplitViewController
        let tabBarController = presentingViewController as? UITabBarController
        let potentialNavigationController = (splitViewController?.viewControllers.first ?? tabBarController?.selectedViewController) ?? presentingViewController
        guard let navigationController = potentialNavigationController as? UINavigationController else {
            Print.warning(.cannotPush, arguments: String(describing: potentialNavigationController.self), required: true)
            return false
        }

        // To avoid overlapping dismiss & pop/push calls, create a transaction block where the menu
        // is dismissed after showing the appropriate screen
        CATransaction.begin()
        defer { CATransaction.commit() }
        var push = false

        if dismissOnPush {
            let animated = animated || alwaysAnimate
            if animated {
                let areAnimationsEnabled = UIView.areAnimationsEnabled
                UIView.setAnimationsEnabled(true)
                transitionController?.transition(presenting: false, animated: animated, alongsideTransition: { [weak self] in
                    guard let self = self else { return }
                    self.activeDelegate?.sideMenuWillDisappear?(menu: self, animated: animated)
                    }, completion: { [weak self] _ in
                        guard let self = self else { return }
                        self.activeDelegate?.sideMenuDidDisappear?(menu: self, animated: animated)
                        self.dismiss(animated: false, completion: nil)
                        completion?(push)
                })
                UIView.setAnimationsEnabled(areAnimationsEnabled)
            }
        }

        if let lastViewController = navigationController.viewControllers.last,
            !allowPushOfSameClassTwice && type(of: lastViewController) == type(of: viewController) {
            return false
        }

        switch pushStyle {
        case .subMenu: return false // handled earlier
        case .defaultBehavior:
            navigationController.pushViewController(viewController, animated: animated)
            return false
        case .popWhenPossible:
            for subViewController in navigationController.viewControllers.reversed() {
                if type(of: subViewController) == type(of: viewController) {
                    navigationController.popToViewController(subViewController, animated: animated)
                    return false
                }
            }
            push = true
            return true
        case .preserve, .preserveAndHideBackButton:
            var viewControllers = navigationController.viewControllers
            let filtered = viewControllers.filter { preservedViewController in type(of: preservedViewController) == type(of: viewController) }
            if let preservedViewController = filtered.last {
                viewControllers = viewControllers.filter { subViewController in subViewController !== preservedViewController }
                if pushStyle == .preserveAndHideBackButton {
                    preservedViewController.navigationItem.hidesBackButton = true
                }
                viewControllers.append(preservedViewController)
                navigationController.setViewControllers(viewControllers, animated: animated)
                return false
            }
            if pushStyle == .preserveAndHideBackButton {
                viewController.navigationItem.hidesBackButton = true
            }

            push = true
            return true
        case .replace:
            viewController.navigationItem.hidesBackButton = true
            navigationController.setViewControllers([viewController], animated: animated)
            return false
        }
    }

    private class func elseCondition(_ propertyName: PropertyName) {
        Print.warning(.property, arguments: propertyName.rawValue, required: true)
    }

    weak var activeDelegate: UISideMenuNavigationControllerDelegate? {
        guard !view.isHidden else { return nil }
        return sideMenuDelegate ?? foundDelegate ?? findDelegate(forViewController: presentingViewController)
    }

    func findDelegate(forViewController: UIViewController?) -> UISideMenuNavigationControllerDelegate? {
        if let navigationController = forViewController as? UINavigationController {
            return findDelegate(forViewController: navigationController.topViewController)
        }
        if let tabBarController = forViewController as? UITabBarController {
            return findDelegate(forViewController: tabBarController.selectedViewController)
        }
        if let splitViewController = forViewController as? UISplitViewController {
            return findDelegate(forViewController: splitViewController.viewControllers.last)
        }

        foundDelegate = forViewController as? UISideMenuNavigationControllerDelegate
        return foundDelegate
    }

    func setup() {
        modalPresentationStyle = .custom

        setupBlur()
        setupSwipeGestures()
        registerForNotifications()
    }

    func setupBlur() {
        removeBlur()

        guard let blurEffectStyle = blurEffectStyle,
            let view = topViewController?.view,
            !UIAccessibility.isReduceTransparencyEnabled else {
                return
        }

        originalBackgroundColor = originalBackgroundColor ?? view.backgroundColor

        let blurEffect = UIBlurEffect(style: blurEffectStyle)
        let blurView = UIVisualEffectView(effect: blurEffect)
        view.backgroundColor = UIColor.clear
        if let tableViewController = topViewController as? UITableViewController {
            tableViewController.tableView.backgroundView = blurView
            tableViewController.tableView.separatorEffect = UIVibrancyEffect(blurEffect: blurEffect)
            tableViewController.tableView.reloadData()
        } else {
            blurView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            blurView.frame = view.bounds
            view.insertSubview(blurView, at: 0)
        }
    }

    func removeBlur() {
        guard let originalBackgroundColor = originalBackgroundColor,
            let view = topViewController?.view else {
                return
        }

        self.originalBackgroundColor = nil
        view.backgroundColor = originalBackgroundColor

        if let tableViewController = topViewController as? UITableViewController {
            tableViewController.tableView.backgroundView = nil
            tableViewController.tableView.separatorEffect = nil
            tableViewController.tableView.reloadData()
        } else if let blurView = view.subviews.first as? UIVisualEffectView {
            blurView.removeFromSuperview()
        }
    }

    func setupSwipeGestures() {
        if let swipeToDismissGesture = swipeToDismissGesture {
            swipeToDismissGesture.view?.removeGestureRecognizer(swipeToDismissGesture)
        }
        if enableSwipeGestures {
            swipeToDismissGesture = addDismissPanGesture(to: view)
        }
    }

    func registerForNotifications() {
        NotificationCenter.default.removeObserver(self)

        [UIApplication.willChangeStatusBarOrientationNotification,
         UIApplication.didChangeStatusBarOrientationNotification,
         UIApplication.willChangeStatusBarFrameNotification].forEach {
            NotificationCenter.default.addObserver(self, selector: #selector(handleNotification), name: $0, object: nil)
        }
    }

    @objc func handleNotification(notification: NSNotification) {
        guard isHidden else { return }

        switch notification.name {
        case UIApplication.willChangeStatusBarOrientationNotification:
            rotating = true
        case UIApplication.didChangeStatusBarOrientationNotification:
            rotating = false
        case UIApplication.willChangeStatusBarFrameNotification:
            // Dismiss for in-call status bar changes but not rotation
            if !rotating {
                dismissMenu(animated: true, interactively: false)
            }
        case UIApplication.didEnterBackgroundNotification:
            if dismissWhenBackgrounded {
                dismissMenu(animated: true, interactively: false)
            }
        default: break
        }
    }

    @discardableResult func addDismissPanGesture(to view: UIView) -> UIPanGestureRecognizer {
        return UIPanGestureRecognizer {
            $0.cancelsTouchesInView = false
            $0.addTarget(self, action: #selector(handleDismissMenuPan(_:)))
            view.addGestureRecognizer($0)
        }
    }

    @objc func handleDismissMenuTap(_ tap: UITapGestureRecognizer) {
        guard view.window?.hitTest(tap.location(in: nil), with: nil) == view.superview else { return }
        dismissMenu(animated: true, interactively: false)
    }

    @objc func handleDismissMenuPan(_ gesture: UIPanGestureRecognizer) {
        handleMenuPan(gesture, false)
    }

    func factor(_ presenting: Bool) -> CGFloat {
        return presenting ? presentFactor : hideFactor
    }

    var presentFactor: CGFloat {
        return leftSide ? 1 : -1
    }

    var hideFactor: CGFloat {
        return -presentFactor
    }
}

// TODO: Move this to its own file
internal extension UIPanGestureRecognizer {

    var canSwitch: Bool {
        return !(self is UIScreenEdgePanGestureRecognizer)
    }

    var xTranslation: CGFloat {
        return view?.untransformed {
            return self.translation(in: view).x
            } ?? 0
    }

    var xVelocity: CGFloat {
        return view?.untransformed {
            return self.velocity(in: view).x
            } ?? 0
    }
}

internal extension UIViewController {

    @objc var isHidden: Bool {
        return presentingViewController == nil
    }
}
